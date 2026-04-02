#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 5 ]]; then
  echo "Usage: $0 <environment> <admin_user> <jumpbox_public_ip> <ssh_private_key_path> <db_node_private_ips_csv>" >&2
  exit 2
fi

# Cleanup function for trap
cleanup() {
  rm -f "$tmp_ssh_config"
  [[ -n "$tmp_extra_vars" ]] && rm -f "$tmp_extra_vars"
}
trap cleanup EXIT INT TERM

# Set readonly variables from script arguments
readonly environment="$1"
readonly admin_user="$2"
readonly jumpbox_ip="$3"
readonly ssh_priv_key_path="$4"
readonly db_node_private_ips_csv="$5"
readonly ssh_dir="$HOME/.ssh"
mkdir -p "$ssh_dir"

# Temporary files variables
tmp_ssh_config="$(mktemp "$ssh_dir/ppg-tmp-ssh-config.XXXXXX")"
tmp_extra_vars=""

# Generate SSH config
{
  echo "Host jumpbox"
  echo "  HostName $jumpbox_ip"
  echo "  User $admin_user"
  echo "  IdentityFile $ssh_priv_key_path"
  echo "  StrictHostKeyChecking no"
  echo "  UserKnownHostsFile /dev/null"
  echo ""
} > "$tmp_ssh_config"

IFS=',' read -ra node_ips <<< "$db_node_private_ips_csv"
if [[ "${#node_ips[@]}" -lt 1 ]]; then
  echo "Expected at least 1 database node IP, got ${#node_ips[@]}" >&2
  exit 2
fi

for idx in "${!node_ips[@]}"; do
  node_ip="${node_ips[$idx]}"
  {
    echo "Host percona-node-vm-$idx $node_ip"
    echo "  HostName $node_ip"
    echo "  User $admin_user"
    echo "  IdentityFile $ssh_priv_key_path"
    echo "  ProxyJump jumpbox"
    echo "  StrictHostKeyChecking no"
    echo "  UserKnownHostsFile /dev/null"
    echo ""
  } >> "$tmp_ssh_config"
done

chmod 600 "$tmp_ssh_config"

# Handle optional extra vars for Azure
if [[ -n "${PGBACKREST_AZURE_ACCOUNT:-}" || -n "${PGBACKREST_AZURE_CONTAINER:-}" ]]; then
  tmp_extra_vars="$(mktemp /tmp/ppg-extra-vars.XXXXXX.yml)"

  [[ -n "${PGBACKREST_AZURE_ACCOUNT:-}" ]] && \
    printf "pgbackrest_azure_account: '%s'\n" "$PGBACKREST_AZURE_ACCOUNT" >> "$tmp_extra_vars"

  [[ -n "${PGBACKREST_AZURE_CONTAINER:-}" ]] && \
    printf "pgbackrest_azure_container: '%s'\n" "$PGBACKREST_AZURE_CONTAINER" >> "$tmp_extra_vars"

  chmod 600 "$tmp_extra_vars"
fi

# Determine script directories securely
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly repo_root="$(cd "$script_dir/.." &>/dev/null && pwd)"
export ANSIBLE_CONFIG="$repo_root/src/ansible/ansible.cfg"

# Build Ansible command arguments dynamically using bash arrays
ansible_args=(
  -i "$repo_root/envs/$environment/ansible/inventory/inventory_azure_rm.yml"
  -i "$repo_root/envs/$environment/ansible/inventory/topology.yml"
  "$repo_root/src/ansible/playbooks/create-pgg-cluster.yml"
  -e "files_glob=$repo_root/envs/$environment/ansible/databases/*.yml"
  -e "ansible_ssh_common_args=-F$tmp_ssh_config"
)

if [[ -n "$tmp_extra_vars" ]]; then
  ansible_args+=("-e" "@$tmp_extra_vars")
fi

# Replace current shell with ansible process
exec ansible-playbook "${ansible_args[@]}"
