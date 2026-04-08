# pgbouncer

Ansible role for installing and configuring [PgBouncer](https://www.pgbouncer.org/) on PostgreSQL cluster nodes, including database-side authentication helpers.

## Requirements

- Debian-based OS
- Percona repository should already be configured on the host
- PgBouncer package must be available from configured repositories
- PostgreSQL must be installed and accessible locally as user `postgres`
- Patroni or PostgreSQL should already be running so the role can query the local server

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `postgres_monitoring_user` | `exporter` | Role granted access to PgBouncer stats |
| `psql_password_encryption` | `scram-sha-256` | Controls `auth_type` and userlist password format |
| `pgbouncer_auth_user` | `pgbouncer_auth` | PostgreSQL role used by PgBouncer for password lookup |
| `pgbouncer_auth_password` | `pgbouncer_auth_password` | Password assigned to `pgbouncer_auth_user` |
| `pgbouncer_config_defaults` | see defaults | Base `[pgbouncer]` settings rendered into `pgbouncer.ini` |
| `pgbouncer_config` | `{}` | Overrides merged into `pgbouncer_config_defaults` with recursive `combine` |
| `pgbouncer_databases_defaults` | `{"*": {"host": ansible_default_ipv4.address, "port": 5432}}` | Base `[databases]` mapping |
| `pgbouncer_databases` | `{}` | Additional or overriding database mappings merged into `pgbouncer_databases_defaults` |
| `pgbouncer_users_defaults` | `{}` | Base `[users]` mapping |
| `pgbouncer_users` | `{}` | Additional or overriding user-specific settings |

## Dynamic Configuration Model

The role now renders `pgbouncer.ini` from structured variables, builds its config from merged defaults and overrides.

- `pgbouncer_config_defaults` contains the shipped defaults for the `[pgbouncer]` section.
- `pgbouncer_config` lets you override only the keys you need.
- `pgbouncer_databases_defaults` and `pgbouncer_databases` control the `[databases]` section.
- `pgbouncer_users_defaults` and `pgbouncer_users` control the `[users]` section.

Dictionary values in `[databases]` are converted to PgBouncer connection strings such as `host=... port=... dbname=...`. List values in `[pgbouncer]` are rendered as comma-separated strings.

## Included Task Files

| File | Description |
|---|---|
| `pgbouncer_auth.yml` | Creates the auth role and lookup function on the leader node |

## Installed Files

| Path | Description |
|---|---|
| `/etc/pgbouncer/pgbouncer.ini` | Generated PgBouncer configuration |
| `/etc/pgbouncer/userlist.txt` | Generated PgBouncer auth file |
| `/etc/logrotate.d/pgbouncer` | logrotate configuration |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/var/log/pgbouncer` | `postgres:adm` | `2755` | PgBouncer log directory |

## Networking

| Port | Protocol | Purpose |
|---|---|---|
| `6432` | TCP | PgBouncer client connections |

PgBouncer forwards traffic to the local PostgreSQL listener on port `5432`.

## Handlers

| Handler | Trigger | Action |
|---|---|---|
| `restart pgbouncer` | PgBouncer config or userlist changed | Restart the `pgbouncer` service |

## Example Playbook

```yaml
- name: "Configure PgBouncer"
  hosts: "pg_nodes"
  become: true
  vars:
    postgres_monitoring_user: "exporter"
    pgbouncer_auth_user: "pgbouncer_auth"
    pgbouncer_auth_password: "StrongPgBouncerPassword"
    pgbouncer_config:
      max_client_conn: 1000
      default_pool_size: 100
      reserve_pool_size: 30
      admin_users:
        - "postgres"
    pgbouncer_databases:
      app:
        host: "127.0.0.1"
        port: 5432
        dbname: "app"
      metrics: "host=127.0.0.1 port=5432 dbname=postgres pool_size=10"
    pgbouncer_users:
      app_user:
        pool_mode: "session"
  roles:
    - role: pgbouncer
```

## Notes

- The role determines whether the local node is the PostgreSQL leader using `SELECT pg_is_in_recovery();` and only creates the auth function on the leader.
- The default database mapping sends all PgBouncer traffic to the local PostgreSQL instance on `{{ ansible_default_ipv4.address }}:5432`, but you can now override or extend it through `pgbouncer_databases`.
- `/etc/pgbouncer/userlist.txt` stores the plain password when `psql_password_encryption` is `scram-sha-256`, and stores `md5` + `md5(password + username)` when it is `md5`.
