# Ansible

This directory contains the Ansible configuration used to prepare hosts and deploy the PostgreSQL HA stack.

## Structure

| Path | Description |
|---|---|
| `ansible.cfg` | Main Ansible configuration |
| `inventory/dev/` | Static development inventory |
| `inventory/azure/` | Azure dynamic inventory and Azure-specific variables |
| `playbooks/create-pgg-cluster.yml` | Main cluster deployment playbook |
| `playbooks/destroy-ppg-cluster.yml` | Cluster cleanup playbook |
| `playbooks/lvm-setup.yml` | Standalone LVM extension playbook |
| `roles/` | Ansible roles for each stack component |

## Inventories

Two inventory modes are present:

- `inventory/dev/hosts.yaml` is a static inventory with `db_cluster`, `pg_nodes`, and `pgbackrest_repo` groups.
- `inventory/azure/inventory_azure_rm.yml` is a dynamic inventory built from Azure VM tags.

`ansible.cfg` currently points to the Azure inventory by default. To use the static development inventory, either pass `-i inventory/dev/hosts.yaml` explicitly or switch the inventory setting in `ansible.cfg`.

## Playbooks

### Create cluster

```bash
ansible-playbook playbooks/create-pgg-cluster.yml
```

Static dev inventory example:

```bash
ansible-playbook -i inventory/dev/hosts.yaml playbooks/create-pgg-cluster.yml
```

### Extend LVM storage

```bash
ansible-playbook -i inventory/dev/hosts.yaml playbooks/lvm-setup.yml
```

### Destroy cluster

```bash
ansible-playbook -i inventory/dev/hosts.yaml playbooks/destroy-ppg-cluster.yml
```

## Deployment Flow

The main playbook applies roles in this order:

1. `percona_repo` on `db_cluster`
2. `lvm` on `db_cluster` when `lvm_state` is defined
3. `pgbackrest` on `db_cluster`
4. `etcd` on `pg_nodes`
5. `postgresql` on `pg_nodes`
6. `patroni` on `pg_nodes`
7. `pgbouncer` on `pg_nodes`

## Roles

Each role has its own README under `roles/<role>/README.md`:

- `etcd`
- `lvm`
- `patroni`
- `percona_repo`
- `pgbackrest`
- `pgbouncer`
- `postgresql`

## Requirements

- Ansible installed
- Required collections available for the roles in use
- SSH access to target hosts
- Vault password file at `.vault_pass.txt`
- Azure CLI authentication if using the Azure dynamic inventory

## Notes

- Sensitive values are stored in Ansible vault files under the relevant inventory group directories.
- The create playbook runs `pgbackrest` on `db_cluster`, so shared backup-topology variables should be visible to all participating hosts at the correct inventory level.
