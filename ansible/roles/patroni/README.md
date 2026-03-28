# patroni

Ansible role for installing and configuring [Patroni](https://patroni.readthedocs.io/) to run a highly available PostgreSQL cluster backed by etcd as the DCS.

## Requirements

- Debian-based OS (uses `apt` for package installation)
- etcd cluster must already be available and reachable on all PostgreSQL nodes
- PostgreSQL binaries for `psql_version` must be installed on target hosts
- pgBackRest should be configured if the default replica bootstrap method is kept as-is

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `psql_version` | `17` | PostgreSQL major version used to build the binary path |
| `psql_data_dir` | `/var/lib/postgresql/data` | PostgreSQL data directory managed by Patroni |
| `psql_bin_dir` | `/usr/lib/postgresql/{{ psql_version }}/bin` | Path to PostgreSQL binaries |
| `psql_superuser_password` | `SuperSecretPassword123!` | Password for PostgreSQL superuser `postgres` |
| `psql_replication_password` | `ReplicationPassword456!` | Password for replication user `replicator` |
| `patroni_scope` | `postgresql-cluster-example` | Patroni cluster scope name |
| `patroni_namespace` | `/example/` | Key prefix used in etcd DCS |
| `patroni_restapi_user` | `admin` | HTTP basic auth user for the Patroni REST API |
| `patroni_restapi_password` | `RestApiPassword789!` | HTTP basic auth password for the Patroni REST API |
| `allow_connection_hosts` | `[]` | Additional inventory hosts allowed in generated `pg_hba` |
| `pgbackrest_stanza` | `ppg-cluster` | pgBackRest stanza used for archive/restore commands |

## Required Inventory Variables

The role also expects the following variables to be defined in inventory or parent group vars:

| Variable | Description |
|---|---|
| `etcd_hosts` | List or Ansible group of hosts used to build the etcd endpoints in Patroni config |
| `postgres_hosts` | List or Ansible group of PostgreSQL nodes used to generate inter-node `pg_hba` rules |

## Installed Packages

The role installs the following packages:

- `patroni`
- `python3-pythonjsonlogger`
- `python3-etcd`
- `python3-requests`
- `python3-yaml`
- `python3-psycopg2`
- `python3-six`
- `python3-systemd`
- `python3-sdnotify`

## Installed Files

| Path | Description |
|---|---|
| `/etc/patroni/config.yml` | Patroni configuration file generated from template |
| `/etc/logrotate.d/postgresql-common` | Logrotate config for PostgreSQL logs |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/etc/patroni` | `root:root` | `0755` | Patroni configuration directory |
| `/var/log/patroni` | `postgres:adm` | `2755` | Patroni log directory |
| `/var/log/postgresql` | `postgres:adm` | `2755` | PostgreSQL log directory |
| `{{ psql_data_dir }}` | `postgres:postgres` | `0700` | PostgreSQL data directory |

## Networking

| Port | Protocol | Purpose |
|---|---|---|
| `5432` | TCP | PostgreSQL client and replication traffic |
| `8008` | TCP | Patroni REST API |

The generated configuration also connects to etcd over HTTP on port `2379` using the hosts listed in `etcd_hosts`.

## Tags

| Tag | Purpose |
|---|---|
| `update_dcs` | Re-render Patroni config and patch the running cluster DCS config through the REST API |

## Handlers

| Handler | Trigger | Action |
|---|---|---|
| `reload_patroni` | Patroni config changed | Reloads the `patroni` service |

## Example Playbook

```yaml
- name: "Create PostgreSQL cluster with Patroni"
  hosts: "pg_nodes"
  become: true
  vars:
    etcd_hosts: "{{ groups['pg_nodes'] }}"
    postgres_hosts: "{{ groups['pg_nodes'] }}"
    patroni_scope: "postgresql-cluster"
    patroni_namespace: "/service/"
    psql_version: "17"
    psql_data_dir: "/var/lib/postgresql/data"
    psql_bin_dir: "/usr/lib/postgresql/17/bin"
    pgbackrest_stanza: "ppg-cluster"
  roles:
    - role: patroni
```

## Notes

- The role stops and disables the default `postgresql` systemd service before enabling Patroni.
- Patroni is configured to use `pgbackrest` as the preferred replica restore method and `basebackup` as fallback.
- After the service starts, the role waits for the local Patroni health endpoint and, if available, patches the running DCS configuration via `http://127.0.0.1:8008/config`.
- The generated `pg_hba` includes all hosts from `postgres_hosts` plus any extra hosts from `allow_connection_hosts`.
