# postgresql

Ansible role for installing Percona PostgreSQL packages and disabling the default distribution-managed PostgreSQL service so Patroni can take control.

## Requirements

- Debian-based OS
- Percona repository should already be configured on the host

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `psql_version` | `17` | PostgreSQL major version used in package names and log file paths |

## Installed Packages

The role installs the following packages:

- `percona-postgresql-{{ psql_version }}`
- `percona-postgresql-server-dev-{{ psql_version }}`

## Example Playbook

```yaml
- name: "Install PostgreSQL packages"
  hosts: "pg_nodes"
  become: true
  vars:
    psql_version: "17"
  roles:
    - role: postgresql
```

## Notes

- The role stops and disables the default `postgresql` systemd service after package installation.
- It removes the default log file `/var/log/postgresql/postgresql-{{ psql_version }}-main.log` to avoid stale package-managed logging artifacts.
- The role does not initialize a PostgreSQL cluster; that is handled later by Patroni.
