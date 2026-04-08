#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  run-create-cluster.sh --admin-user <user> --ssh-private-key-path <path> \
    --db-node-private-ips-csv <ip1,ip2,...> --vm-name-prefix <prefix> \
    [--vault-password-file <path|->] [--inventory-files-csv <file1,file2,...>] \
    [--pgbackrest-azure-account <account>] [--pgbackrest-azure-container <container>] \
    [--playbook <path>]
EOF
}

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

# Parse script arguments.
admin_user=""
ssh_priv_key_path=""
db_node_private_ips_csv=""
vm_name_prefix=""
vault_password_file="-"
inventory_files_csv=""
pgbackrest_azure_account="${PGBACKREST_AZURE_ACCOUNT:-}"
pgbackrest_azure_container="${PGBACKREST_AZURE_CONTAINER:-}"
playbook="playbooks/create-pgg-cluster.azure.yml"

if [[ "$#" -eq 0 ]]; then
  usage
  exit 2
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --admin-user)
      admin_user="${2:-}"
      shift 2
      ;;
    --ssh-private-key-path)
      ssh_priv_key_path="${2:-}"
      shift 2
      ;;
    --db-node-private-ips-csv)
      db_node_private_ips_csv="${2:-}"
      shift 2
      ;;
    --vm-name-prefix)
      vm_name_prefix="${2:-}"
      shift 2
      ;;
    --vault-password-file)
      vault_password_file="${2:-}"
      shift 2
      ;;
    --inventory-files-csv)
      inventory_files_csv="${2:-}"
      shift 2
      ;;
    --pgbackrest-azure-account)
      pgbackrest_azure_account="${2:-}"
      shift 2
      ;;
    --pgbackrest-azure-container)
      pgbackrest_azure_container="${2:-}"
      shift 2
      ;;
    --playbook)
      playbook="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$admin_user" || -z "$ssh_priv_key_path" || -z "$db_node_private_ips_csv" || -z "$vm_name_prefix" ]]; then
  echo "Missing required arguments" >&2
  usage
  exit 2
fi

readonly admin_user
readonly ssh_priv_key_path
readonly db_node_private_ips_csv
readonly vm_name_prefix
readonly vault_password_file
readonly inventory_files_csv
readonly pgbackrest_azure_account
readonly pgbackrest_azure_container
readonly playbook
readonly ssh_dir="/home/$admin_user/.ssh"
readonly extra_vars_dir="/home/$admin_user/.ansible-tmp"
mkdir -p "$ssh_dir" "$extra_vars_dir"

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
if [[ -n "$pgbackrest_azure_account" || -n "$pgbackrest_azure_container" ]]; then
  tmp_extra_vars="$(mktemp "$extra_vars_dir/ppg-extra-vars.XXXXXX.yml")"

  [[ -n "$pgbackrest_azure_account" ]] && \
    printf "pgbackrest_azure_account: '%s'\n" "$pgbackrest_azure_account" >> "$tmp_extra_vars"

  [[ -n "$pgbackrest_azure_container" ]] && \
    printf "pgbackrest_azure_container: '%s'\n" "$pgbackrest_azure_container" >> "$tmp_extra_vars"

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

if [[ "$playbook" = /* ]]; then
  playbook_path="$playbook"
else
  playbook_path="$ansible_root/$playbook"
fi

if [[ ! -f "$playbook_path" ]]; then
  echo "Playbook not found: $playbook_path" >&2
  exit 2
fi

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
