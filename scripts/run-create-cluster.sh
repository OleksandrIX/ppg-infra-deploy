#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 4 || "$#" -gt 6 ]]; then
  echo "Usage: $0 <admin_user> <ssh_private_key_path> <db_node_private_ips_csv> <vm_name_prefix> [vault_password_file|-] [inventory_files_csv]" >&2
  exit 2
fi

# Temporary files — must be declared before trap so cleanup sees them under set -u
tmp_ssh_config=""
tmp_extra_vars=""

# Cleanup function for trap
cleanup() {
  [[ -n "$tmp_ssh_config" ]] && rm -f "$tmp_ssh_config"
  [[ -n "$tmp_extra_vars" ]] && rm -f "$tmp_extra_vars"
  return 0
}
trap cleanup EXIT INT TERM

# Set readonly variables from script arguments
readonly admin_user="$1"
readonly ssh_priv_key_path="$2"
readonly db_node_private_ips_csv="$3"
readonly vm_name_prefix="$4"
readonly vault_password_file="${5:--}"
readonly inventory_files_csv="${6:-}"
readonly ssh_dir="/home/$admin_user/.ssh"
mkdir -p "$ssh_dir"

tmp_ssh_config="$(mktemp "$ssh_dir/ppg-tmp-ssh-config.XXXXXX")"

# Generate SSH config
: > "$tmp_ssh_config"

IFS=',' read -ra node_ips <<< "$db_node_private_ips_csv"
if [[ "${#node_ips[@]}" -lt 1 ]]; then
  echo "Expected at least 1 database node IP, got ${#node_ips[@]}" >&2
  exit 2
fi

for idx in "${!node_ips[@]}"; do
  node_ip="${node_ips[$idx]}"
  node_num=$((idx + 1))
  {
    echo "Host ${vm_name_prefix}-vm-$node_num $node_ip"
    echo "  HostName $node_ip"
    echo "  User $admin_user"
    echo "  IdentityFile $ssh_priv_key_path"
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

# Use only ansible bundle mode (wrapper executes on ansible-host).
if [[ -z "${ANSIBLE_BUNDLE_ROOT:-}" ]]; then
  echo "ANSIBLE_BUNDLE_ROOT must be set (expected /home/<user>/ansible on ansible-host)" >&2
  exit 2
fi

if [[ ! -d "${ANSIBLE_BUNDLE_ROOT}" ]]; then
  echo "ANSIBLE_BUNDLE_ROOT not found: ${ANSIBLE_BUNDLE_ROOT}" >&2
  exit 2
fi

readonly ansible_root="$ANSIBLE_BUNDLE_ROOT"
readonly env_inventory_dir="$ANSIBLE_BUNDLE_ROOT/inventory"
readonly files_glob="$ANSIBLE_BUNDLE_ROOT/databases/*.yml"
readonly log_dir="/home/$admin_user/logs"
readonly log_file="$log_dir/ansible-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$log_dir"
chown "$admin_user:$admin_user" "$log_dir" || true

export ANSIBLE_CONFIG="$ansible_root/ansible.cfg"

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
playbook_path="$ansible_root/playbooks/create-pgg-cluster.yml"

for inventory_file in "${inventory_files[@]}"; do
  ansible_args+=("-i" "$inventory_file")
done

if [[ -n "$tmp_extra_vars" ]]; then
  ansible_args+=("-e" "@$tmp_extra_vars")
fi

if [[ -n "${ANSIBLE_EXTRA_VARS_FILE:-}" ]]; then
  if [[ ! -f "${ANSIBLE_EXTRA_VARS_FILE}" ]]; then
    echo "ANSIBLE_EXTRA_VARS_FILE not found: ${ANSIBLE_EXTRA_VARS_FILE}" >&2
    exit 2
  fi
  ansible_args+=("-e" "@${ANSIBLE_EXTRA_VARS_FILE}")
fi

ansible_args+=(
  -e "ansible_ssh_common_args=-F$tmp_ssh_config"
  -e "files_glob=$files_glob"
)

if [[ "$vault_password_file" != "-" && -n "$vault_password_file" ]]; then
  ansible_args+=("--vault-password-file=$vault_password_file")
fi

ansible_args+=("$playbook_path")

set +e
echo "Ansible log: $log_file"
ansible-playbook "${ansible_args[@]}" >>"$log_file" 2>&1
ansible_rc=$?
set -e

if [ "$ansible_rc" -ne 0 ]; then
  echo "Ansible failed with return code $ansible_rc"
  exit "$ansible_rc"
fi

echo "Ansible finished successfully"
