# Ansible

This directory contains the Ansible configuration used to prepare hosts and deploy the PostgreSQL HA stack.

## Structure

| Path | Description |
|---|---|
| `ansible.cfg` | Main Ansible configuration |
| `inventory/<environment>/` | Invetory for specific environment |
| `inventory/<environment>/databases/` | Vault-encrypted database spec files for post-initialization |
| `playbooks/create-pgg-cluster.yml` | Main cluster deployment playbook |
| `playbooks/destroy-ppg-cluster.yml` | Cluster cleanup playbook |
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

Run only PostgreSQL post-initialization (users/databases/grants/extensions):

```bash
ansible-playbook playbooks/create-pgg-cluster.yml -t post_init
```

### Destroy cluster

```bash
ansible-playbook -i inventory/dev/hosts.yaml playbooks/destroy-ppg-cluster.yml
```

## Deployment Flow

The main playbook applies roles in this order:

1. `percona_repo` on `db_cluster`
2. `lvm` on `db_cluster` when `pv_devices` is defined and non-empty
3. `pgbackrest` on `db_cluster`
4. `etcd` on `pg_nodes`
5. `postgresql` on `pg_nodes`
6. `patroni` on `pg_nodes`
7. `pgbouncer` on `pg_nodes`
8. `haproxy_keepalived` on `pg_nodes` (only when `pgbackrest_repo_type != "azure"`)
9. `pg_post_init` on `pg_nodes`

## Roles

Each role has its own README under `roles/<role>/README.md`:

- [etcd](roles/etcd/README.md)
- [lvm](roles/lvm/README.md)
- [patroni](roles/patroni/README.md)
- [percona_repo](roles/percona_repo/README.md)
- [pgbackrest](roles/pgbackrest/README.md)
- [pgbouncer](roles/pgbouncer/README.md)
- [pg_post_init](roles/pg_post_init/README.md)
- [postgresql](roles/postgresql/README.md)
- [haproxy_keepalived](roles/haproxy_keepalived/README.md)

## Requirements

- Ansible installed
- Required collections available for the roles in use
- SSH access to target hosts
- Vault password file at `.vault_pass.txt`
- Azure CLI authentication if using the Azure dynamic inventory

## Notes

- Sensitive values are stored in Ansible vault files under the relevant inventory group directories.
- The create playbook runs `pgbackrest` on `db_cluster`, so shared backup-topology variables should be visible to all participating hosts at the correct inventory level.
- Database post-initialization is managed by specs in `inventory/<environment>/databases/*.yml` (one `database_spec` per file, intended to be encrypted with Ansible Vault).
- For database users, use `password_env` in specs and pass secrets as environment variables at runtime.
