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
| `pgbouncer_auth_user` | `pgbouncer_auth` | PostgreSQL role used by PgBouncer for password lookup |
| `pgbouncer_auth_password` | `pgbouncer_auth_password` | Password assigned to `pgbouncer_auth_user` |

## Included Task Files

| File | Description |
|---|---|
| `pgbouncer_auth.yml` | Creates the auth role and lookup function on the leader node and reads the password hash |

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
  roles:
    - role: pgbouncer
```

## Notes

- The role determines whether the local node is the PostgreSQL leader using `SELECT pg_is_in_recovery();` and only creates the auth function on the leader.
- `userlist.txt` is generated from the password hash fetched from PostgreSQL, not from the clear-text password variable.
- The default database mapping sends all PgBouncer traffic to the local PostgreSQL instance on `{{ ansible_default_ipv4.address }}:5432`.
