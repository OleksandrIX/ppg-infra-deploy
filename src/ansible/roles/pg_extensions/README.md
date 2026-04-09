# pg_extensions

Ansible role for installing PostgreSQL extension OS packages on cluster nodes.

## Requirements

- PostgreSQL must already be installed and running
- Database spec files must exist under `databases/*.yml`
- Vault password access must be configured to decrypt database spec files

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `files_glob` | `{{ inventory_dir }}/databases/*.yml` | Glob pattern used to discover database spec files |
| `extension_map` | see [defaults](defaults/main.yml) | Mapping `extension_name -> {packages, repo, install_script}` for extensions missing on the node |

## Included Task Files

| File | Description |
|---|---|
| `discover.yml` | Discovers and normalizes all `database_spec` files |
| `extension_packages.yml` | Collects extensions from spec files, adds required repos and installs OS packages |

## Extension Package Resolution

- Role collects all extensions declared in `databases[].extensions`
- Extensions already available on the node require no package mapping
- Missing extensions require an entry in `extension_map`
- After package installation the role re-validates availability and fails fast if an extension is still missing

## Example Playbook

```yaml
- name: "Install PostgreSQL extension packages (optional)"
  hosts: "pg_nodes"
  become: true
  roles:
    - role: pg_extensions
```

## Notes

- Discovery runs once and is propagated to all hosts via `run_once`
- This role does **not** run `CREATE EXTENSION` — add extensions to the database spec for that

## Extension Map Structure

Each extension in `extension_map` can be installed in one of three ways:

- **Via OS packages** (with optional apt repo):
  - Use `packages` and optionally `repo` (with `key_url`/`repo` or `script`).
- **Via custom install script**:
  - Use `install_script` for arbitrary installation logic (local or remote build, etc).

### Example

```yaml
extension_map:
  timescaledb:
    packages:
      - timescaledb-2-postgresql-{{ psql_version }}
    repo:
      # Either use key_url+repo+name, or script (not both)
      key_url: "https://packagecloud.io/timescale/timescaledb/gpgkey"
      repo: "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ {{ ansible_distribution_release }} main"
      # OR
      script: "curl -s https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | sudo bash"
      name: timescaledb
  postgis:
    packages:
      - percona-postgresql-{{ psql_version }}-postgis-3
  redis_fdw:
    install_script: |
      apt install -y libhiredis-dev postgresql-server-dev-16 clang-18 git
      cd /tmp
      git clone https://github.com/pg-redis-fdw/redis_fdw.git -b REL_16_STABLE
      cd redis_fdw
      make USE_PGXS=1
      sudo make install USE_PGXS=1
```

- If `install_script` is present, it is run after all packages are installed.
- If `repo.script` is present, it is run before package install (instead of key_url/repo).
- If both `key_url` and `repo` are present (and no script), the repo is added via apt_key/apt_repository.
