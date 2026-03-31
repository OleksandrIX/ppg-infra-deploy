# pgbackrest

Ansible role for installing and configuring [pgBackRest](https://pgbackrest.org/) for PostgreSQL backups. The role supports both POSIX repository hosts and Azure Blob Storage repositories.

## Requirements

- `percona-pgbackrest` package must be available from configured repositories
- PostgreSQL hosts must have a valid `postgres` home directory
- For POSIX mode, the repository host must be reachable from PostgreSQL nodes
- For Azure mode, blob storage credentials must be available in inventory or vault

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `postgres_hosts` | `[]` | PostgreSQL hosts included in backup topology |
| `pgbackrest_repo_type` | `posix` | Repository type: `posix` or `azure` |
| `pgbackrest_stanza` | `test-stanza` | pgBackRest stanza name |
| `pgbackrest_cipher_pass` | `cipher pass` | Encryption passphrase for repository data |
| `psql_data_dir` | `/var/lib/postgresql/data` | PostgreSQL data directory path |
| `pgbackrest_repo_host` | `pgbackrest-repo-host` | Repository host for POSIX mode |
| `pgbackrest_repo_path` | `/var/lib/pgbackrest` | Repository path for POSIX mode |
| `pgbackrest_azure_account` | `testaccount` | Azure storage account name |
| `pgbackrest_azure_key` | `testkey` | Azure storage account key |
| `pgbackrest_azure_container` | `testcontainer` | Azure blob container name |

## Required Inventory Variables

The role also expects the following variables to be defined outside the role defaults:

| Variable | Description |
|---|---|
| `psql_home_dir` | Home directory of the `postgres` user on PostgreSQL hosts |

## Included Task Files

| File | Description |
|---|---|
| `install.yml` | Installs `percona-pgbackrest` and removes the default config |
| `user.yml` | Dispatches SSH/user setup for repository and PostgreSQL hosts |
| `user_repo.yml` | Prepares repository directories and configures SSH trust from repo host to PostgreSQL hosts in POSIX mode |
| `user_pg.yml` | Prepares SSH directories on PostgreSQL hosts and configures peer trust for Azure mode |
| `config.yml` | Generates pgBackRest configuration and logrotate files |

## Installed Files

| Path | Description |
|---|---|
| `/etc/pgbackrest/pgbackrest.conf` | Generated pgBackRest configuration |
| `/etc/logrotate.d/pgbackrest` | logrotate configuration |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/etc/pgbackrest` | `postgres:postgres` | `0750` | Configuration directory |
| `{{ psql_home_dir }}/.ssh` | `postgres:postgres` | `0700` | SSH directory for `postgres` user |
| `{{ pgbackrest_repo_path }}` | `postgres:postgres` | `0750` | POSIX backup repository path |
| `{{ psql_home_dir }}/.ssh/id_ed25519` | `postgres:postgres` | `0600` | Repository SSH private key in POSIX mode |
| `{{ psql_home_dir }}/.ssh/id_ed25519.pub` | `postgres:postgres` | `0644` | Repository SSH public key in POSIX mode |

## Example Playbook

```yaml
- name: "Configure pgBackRest"
  hosts: "db_cluster"
  become: true
  vars:
    postgres_hosts: "{{ groups['pg_nodes'] }}"
    psql_home_dir: "/var/lib/postgresql"
    pgbackrest_stanza: "ppg-cluster"
    pgbackrest_repo_type: "posix"
    pgbackrest_repo_host: "backup-01"
    pgbackrest_repo_path: "/mnt/pgbackrest/ppg-cluster"
  roles:
    - role: pgbackrest
```

## Notes

- In POSIX mode the repository host is addressed via `hostvars[pgbackrest_repo_host]['ansible_default_ipv4']['address']`.
- In POSIX mode SSH keys are generated on the repository host and the repository public key is installed on all PostgreSQL hosts.
- In POSIX mode stanza on the repository host includes all hosts from `postgres_hosts`, while each PostgreSQL host keeps only `pg1-path` in stanza.
- In Azure mode the role configures peer SSH trust between PostgreSQL hosts using generated ed25519 keys.
- Both configuration templates enable AES-256-CBC repository encryption and a fixed retention policy of 3 full and 1 differential backup.
- The role assumes PostgreSQL hosts are reachable by the IP addresses available in `hostvars`.
