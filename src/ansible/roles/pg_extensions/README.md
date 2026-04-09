# pg_extensions

Ansible role for installing PostgreSQL extension OS packages on cluster nodes.

This role is **optional** and designed to be included independently of [`pg_post_init`](../pg_post_init/README.md). It only installs packages — it does **not** run `CREATE EXTENSION` in any database. Extension enablement per database is handled by `pg_post_init`.

## Requirements

- PostgreSQL must already be installed and running
- Database spec files must exist under `inventory/<environment>/databases/*.yml`
- Vault password access must be configured to decrypt database spec files

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `files_glob` | `{{ inventory_dir }}/databases/*.yml` | Glob pattern used to discover database spec files |
| `extension_map` | see [defaults](defaults/main.yml) | Mapping `extension_name -> {packages, repo}` for extensions missing on the node |

## Included Task Files

| File | Description |
|---|---|
| `discover.yml` | Discovers and normalizes all `database_spec` files |
| `extension_packages.yml` | Collects extensions from spec files, adds required repos and installs OS packages |

## Extension Package Resolution

- Role collects all extensions declared in `databases[].extensions`
- Extensions already available on the node require no package mapping
- Missing extensions require an entry in `extension_package_map`
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
