# percona_repo

Ansible role for enabling the Percona PostgreSQL package repository on target hosts.

## Requirements

- Debian-based or RedHat-based OS
- Internet access to download the Percona release package
- Privileged access for package management and repository changes

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `psql_version` | `17` | PostgreSQL major version used when enabling the `ppg` repository |

## Included Task Files

| File | Description |
|---|---|
| `debian.yml` | Updates APT cache, installs `percona-release`, and enables the Debian repo |
| `redhat.yml` | Updates DNF packages, installs `percona-release`, and enables the RedHat repo |

## Installed Files

The exact repository file depends on the operating system:

| Path | Description |
|---|---|
| `/etc/apt/sources.list.d/percona-ppg-{{ psql_version }}-release.list` | Debian/Ubuntu repository definition |
| `/etc/yum.repos.d/percona-ppg-{{ psql_version }}-release.repo` | RedHat repository definition |

## Example Playbook

```yaml
- name: "Enable Percona PostgreSQL repository"
  hosts: "db_cluster"
  become: true
  vars:
    psql_version: "17"
  roles:
    - role: percona_repo
```

## Notes

- The role runs `percona-release setup ppg-{{ psql_version }}` and avoids re-running it when the target repository file already exists.
- On Debian-family systems the role performs `apt upgrade: dist` before enabling the repository.
- On RedHat-family systems the role updates all installed packages to the latest available version before enabling the repository.
