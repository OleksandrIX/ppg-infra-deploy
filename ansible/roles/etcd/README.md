# etcd

Ansible role for installing and configuring [etcd](https://etcd.io/) as the distributed configuration store used by Patroni for PostgreSQL cluster coordination.

## Requirements

- Debian-based OS
- Internet access on target hosts to download the release archive from GitHub
- Target architecture `linux-amd64`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `etcd_version` | `v3.5.18` | etcd release version to install |
| `etcd_hosts` | `local` | List or Ansible group of hosts used to build `initial-cluster` |
| `etcd_cluster_state` | `new` | Default cluster state value |
| `etcd_cluster_token` | `etcd-cluster-example` | Unique token identifying the etcd cluster |
| `etcd_data_dir` | `/var/lib/etcd/example` | Directory where etcd stores its data |

## Installed Files

| Path | Description |
|---|---|
| `/usr/local/bin/etcd` | etcd server binary |
| `/usr/local/bin/etcdctl` | etcd command-line client |
| `/usr/local/bin/etcdutl` | etcd utility binary |
| `/etc/etcd/config.yaml` | Generated etcd configuration |
| `/etc/systemd/system/etcd.service` | systemd unit file |
| `/etc/logrotate.d/etcd` | logrotate configuration |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/etc/etcd` | `etcd:etcd` | `0755` | Configuration directory |
| `/var/lib/etcd` | `etcd:etcd` | `0755` | Data directory root |
| `/var/log/etcd` | `etcd:adm` | `2755` | Log directory |

## Networking

| Port | Protocol | Purpose |
|---|---|---|
| `2379` | TCP | Client traffic from Patroni and operators |
| `2380` | TCP | Peer replication traffic between etcd nodes |

All listeners are configured on the host default IPv4 address and use plain HTTP by default.

## Handlers

| Handler | Trigger | Action |
|---|---|---|
| `restart etcd` | etcd config changed | Restarts the `etcd` service |

## Example Playbook

```yaml
- name: "Deploy etcd cluster"
  hosts: "pg_nodes"
  become: true
  vars:
    etcd_version: "v3.5.18"
    etcd_hosts: "{{ groups['pg_nodes'] }}"
    etcd_cluster_token: "pg-etcd-cluster-01"
    etcd_data_dir: "/var/lib/etcd/pg-cluster"
  roles:
    - role: etcd
```

## Notes

- The role downloads the release archive into `/tmp` and removes it after installation.
- `etcd_hosts` should resolve to the complete cluster membership so the generated `initial-cluster` value is correct.
- The role checks for `{{ etcd_data_dir }}/member` and renders `initial-cluster-state` as `existing` when data already exists.
- After the first successful start, the role rewrites `initial-cluster-state` to `existing` to avoid accidental re-bootstrap on later runs.
