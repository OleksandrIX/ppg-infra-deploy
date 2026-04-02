#!/usr/bin/env sh
set -eu

if [ "$#" -ne 6 ]; then
  echo "Usage: $0 <environment> <admin_user> <jumpbox_public_ip> <ssh_private_key_path> <vault_password_file> <db_node_private_ips_csv>" >&2
  exit 2
fi

environment="$1"
admin_user="$2"
jumpbox_ip="$3"
ssh_priv_key_path="$4"
vault_password_file="$5"
db_node_private_ips_csv="$6"

ssh_dir="$HOME/.ssh"
mkdir -p "$ssh_dir"
tmp_ssh_config="$(mktemp "$ssh_dir/ppg-tmp-ssh-config.XXXXXX")"
tmp_extra_vars=""

cleanup() {
  rm -f "$tmp_ssh_config"
  rm -f "$tmp_extra_vars"
}

trap cleanup EXIT INT TERM

{
  echo "Host jumpbox"
  echo "  HostName $jumpbox_ip"
  echo "  User $admin_user"
  echo "  IdentityFile $ssh_priv_key_path"
  echo "  StrictHostKeyChecking no"
  echo "  UserKnownHostsFile /dev/null"
  echo ""
} > "$tmp_ssh_config"

old_ifs="$IFS"
IFS=','
set -- $db_node_private_ips_csv
IFS="$old_ifs"

if [ "$#" -lt 1 ]; then
  echo "Expected at least 1 database node IP, got $#" >&2
  exit 2
fi

idx=0
for node_ip in "$@"; do
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
  idx=$((idx + 1))
done

chmod 600 "$tmp_ssh_config"

if [ -n "${PGBACKREST_AZURE_ACCOUNT:-}" ] || [ -n "${PGBACKREST_AZURE_CONTAINER:-}" ]; then
  tmp_extra_vars="$(mktemp /tmp/ppg-extra-vars.XXXXXX.yml)"
  : > "$tmp_extra_vars"
  if [ -n "${PGBACKREST_AZURE_ACCOUNT:-}" ]; then
    printf "pgbackrest_azure_account: '%s'\n" "$PGBACKREST_AZURE_ACCOUNT" >> "$tmp_extra_vars"
  fi
  if [ -n "${PGBACKREST_AZURE_CONTAINER:-}" ]; then
    printf "pgbackrest_azure_container: '%s'\n" "$PGBACKREST_AZURE_CONTAINER" >> "$tmp_extra_vars"
  fi
  chmod 600 "$tmp_extra_vars"
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"

export ANSIBLE_CONFIG="$repo_root/src/ansible/ansible.cfg"

set -- \
  -i "$repo_root/envs/$environment/ansible/inventory/inventory_azure_rm.yml" \
  -i "$repo_root/envs/$environment/ansible/inventory/topology.yml" \
  "$repo_root/src/ansible/playbooks/create-pgg-cluster.yml" \
  -e "files_glob=$repo_root/envs/$environment/ansible/databases/*.yml" \
  -e "ansible_ssh_common_args=-F$tmp_ssh_config" \
  --vault-password-file "$vault_password_file"

if [ -n "$tmp_extra_vars" ]; then
  set -- "$@" -e "@$tmp_extra_vars"
fi

ansible-playbook "$@"
