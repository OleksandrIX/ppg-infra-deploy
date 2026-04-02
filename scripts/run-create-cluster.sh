#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 7 || "$#" -gt 8 ]]; then
  echo "Usage: $0 <environment> <admin_user> <jumpbox_public_ip> <ssh_private_key_path> <db_node_private_ips_csv> <vm_name_prefix> <vault_password_file> [inventory_files_csv]" >&2
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
readonly vm_name_prefix="$6"
readonly vault_password_file="$7"
readonly inventory_files_csv="${8:-}"
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
    echo "Host ${vm_name_prefix}-vm-$idx $node_ip"
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
readonly env_inventory_dir="$repo_root/envs/$environment/ansible/inventory"
export ANSIBLE_CONFIG="$repo_root/src/ansible/ansible.cfg"

# Build inventory argument list dynamically.
inventory_files=()

if [[ -n "$inventory_files_csv" ]]; then
  inventory_files=()
  IFS=',' read -ra raw_inventory_files <<< "$inventory_files_csv"

  if [[ "${#raw_inventory_files[@]}" -lt 1 ]]; then
    echo "Expected at least one inventory file in inventory_files_csv" >&2
    exit 2
  fi

  for raw_file in "${raw_inventory_files[@]}"; do
    file="${raw_file#"${raw_file%%[![:space:]]*}"}"
    file="${file%"${file##*[![:space:]]}"}"

    if [[ -z "$file" ]]; then
      echo "Inventory file list contains an empty value" >&2
      exit 2
    fi

    if [[ "$file" = /* ]]; then
      inventory_path="$file"
    else
      inventory_path="$env_inventory_dir/$file"
    fi

    if [[ ! -f "$inventory_path" ]]; then
      echo "Inventory file not found: $inventory_path" >&2
      exit 2
    fi

    inventory_files+=("$inventory_path")
  done
fi

# Build Ansible command arguments dynamically using bash arrays
ansible_args=()

for inventory_file in "${inventory_files[@]}"; do
  ansible_args+=("-i" "$inventory_file")
done

if [[ -n "$tmp_extra_vars" ]]; then
  ansible_args+=("-e" "@$tmp_extra_vars")
fi

ansible_args+=(
  -e "ansible_ssh_common_args=-F$tmp_ssh_config"
  -e "files_glob=$repo_root/envs/$environment/ansible/databases/*.yml"
  --vault-password-file="$vault_password_file"
  "$repo_root/src/ansible/playbooks/create-pgg-cluster.yml"
)

# Replace current shell with ansible process
exec ansible-playbook "${ansible_args[@]}"
