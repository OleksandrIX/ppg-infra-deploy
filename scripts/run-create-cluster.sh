#!/usr/bin/env sh
set -eu

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
  echo "Usage: $0 <environment> <admin_user> <jumpbox_public_ip> <ssh_private_key_path> <vault_password_file> [verbosity]" >&2
  exit 2
fi

environment="$1"
admin_user="$2"
jumpbox_ip="$3"
ssh_priv_key_path="$4"
vault_password_file="$5"

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"

export ANSIBLE_CONFIG="$repo_root/src/ansible/ansible.cfg"

ansible-playbook \
  -i "$repo_root/envs/$environment/ansible/inventory/inventory_azure_rm.yml" \
  -i "$repo_root/envs/$environment/ansible/inventory/topology.yml" \
  "$repo_root/src/ansible/playbooks/create-pgg-cluster.yml" \
  -e "files_glob=$repo_root/envs/$environment/ansible/databases/*.yml" \
  -e "ansible_user=$admin_user" \
  -e "ansible_ssh_private_key_file=$ssh_priv_key_path" \
  -e "ansible_ssh_common_args=-oProxyJump=$admin_user@$jumpbox_ip -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null" \
  --vault-password-file "$vault_password_file"
