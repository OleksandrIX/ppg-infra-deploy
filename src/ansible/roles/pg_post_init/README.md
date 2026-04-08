# pg_post_init

Ansible role for declarative post-initialization of a PostgreSQL cluster: create users, databases, and grants from vault-encrypted inventory files.

## Requirements

- PostgreSQL and Patroni must already be installed and running
- `community.postgresql` collection must be installed on the control node
- Database spec files must exist under `inventory/<environment>/databases/*.yml`
- Vault password access must be configured to decrypt database spec files

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `files_glob` | `{{ inventory_dir }}/databases/*.yml` | Glob pattern used to discover database spec files |
| `allowed_grant_types` | see [defaults](defaults/main.yml) | Allowed values for `users[].grants[].type` |
| `allowed_grant_privileges` | see [defaults](defaults/main.yml) | Allowed privileges per grant type |

## Included Task Files

| File | Description |
|---|---|
| `discover.yml` | Discovers and normalizes all `database_spec` files |
| `validate.yml` | Validates schema, uniqueness, and grant consistency rules |
| `detect_primary.yml` | Detects whether the current node is PostgreSQL primary |
| `users.yml` | Ensures PostgreSQL users exist |
| `databases.yml` | Ensures PostgreSQL databases exist |
| `grants.yml` | Ensures grants from spec are applied |
| `extensions.yml` | Ensures declared extensions are enabled in each database |

## Database Spec Format

Each file must contain exactly one `database_spec` object.

```yaml
database_spec:
  name: app_db
  owner: app_user
  users:
    - name: app_user
      password_env: APP_DB_USER_PASSWORD
      role_attr_flags: "LOGIN"
      grants:
        - type: database
          privs: "ALL"
  extensions:
    - pgcrypto
    - "uuid-ossp"
```

Password sources for users:
- `password_env`: name of environment variable that contains password (required)

## Validation Rules

- `owner` must exist in `users` list for the same spec
- `users` must be present and non-empty
- each `users[]` entry must have non-empty `grants`
- `owner` must have at least one `type: database` grant
- `users[].grants[].type` must be in `allowed_grant_types`
- `users[].grants[].privs` must match the whitelist for selected type
- database names must be unique across all files
- user names must be unique across all files

## Vault Workflow

Create encrypted spec file:

```bash
ansible-vault create inventory/dev/databases/10-app.yml
```

Edit encrypted spec file:

```bash
ansible-vault edit inventory/dev/databases/10-app.yml
```

Encrypt existing plaintext file:

```bash
ansible-vault encrypt inventory/dev/databases/10-app.yml
```

## Example Playbook

```yaml
- name: "PostgreSQL Post-Initialization"
  hosts: "pg_nodes"
  become: true
  roles:
    - role: pg_post_init
```

Run only this role via tag:

```bash
ansible-playbook playbooks/create-pgg-cluster.yml -t post_init
```

## Notes

- Discovery and validation steps are executed once on localhost and propagated to all hosts
- Write operations run only on the detected primary node
- Role uses `community.postgresql` modules for idempotent user/database/grant/extension management
