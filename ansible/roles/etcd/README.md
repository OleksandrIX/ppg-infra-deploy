# etcd

Ansible role for installing and configuring [etcd](https://etcd.io/) — a distributed key-value store used by Patroni as a DCS (Distributed Configuration Store) for PostgreSQL HA cluster coordination.

## Requirements

- Debian-based OS
- Internet access on target hosts (binary is downloaded from GitHub releases)
- Target architecture: `linux-amd64`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `etcd_version` | `v3.5.18` | etcd release version to download and install |
| `etcd_hosts` | `local` | Ansible group or list of hosts forming the etcd cluster; used to build `initial-cluster` |
| `etcd_cluster_state` | `new` | Initial cluster state (`new` or `existing`) |
| `etcd_cluster_token` | `etcd-cluster-example` | Unique token to identify the etcd cluster |
| `etcd_data_dir` | `/var/lib/etcd/example` | Directory where etcd stores its data |

## Installed Files

| Path | Description |
|---|---|
| `/usr/local/bin/etcd` | etcd server binary |
| `/usr/local/bin/etcdctl` | CLI client for etcd |
| `/usr/local/bin/etcdutl` | Utility tool for etcd data operations |
| `/etc/etcd/config.yaml` | etcd configuration file (generated from template) |
| `/etc/systemd/system/etcd.service` | systemd unit file |
| `/etc/logrotate.d/etcd` | logrotate configuration |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/etc/etcd` | `etcd:etcd` | `0755` | Configuration directory |
| `/var/lib/etcd` | `etcd:etcd` | `0755` | Data directory |
| `/var/log/etcd` | `etcd:adm` | `2755` | Log directory (SGID for group log access) |

## Networking

| Port | Protocol | Purpose |
|---|---|---|
| `2379` | TCP | Client communication (etcd clients / Patroni) |
| `2380` | TCP | Peer communication (inter-cluster replication) |

etcd listens on the host's default IPv4 address. All communication is plain HTTP (no TLS by default).

## Idempotency

The role detects whether an etcd data directory (`{{ etcd_data_dir }}/member`) already exists. If it does, the config is rendered with `initial-cluster-state: existing` instead of `new`, preventing accidental cluster re-initialization on subsequent runs.

## Handlers

| Handler | Trigger | Action |
|---|---|---|
| `restart etcd` | etcd config changed | Restarts the `etcd` systemd service |

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

- The role downloads the etcd tarball to `/tmp` and removes it after installation.
- `etcd_hosts` should reference the Ansible group that contains all nodes intended to form the etcd cluster (typically the same group as PostgreSQL nodes).
- The `initial-cluster` value in the configuration is built dynamically from `hostvars` of all hosts in `etcd_hosts`, using their `ansible_default_ipv4.address`.
- After service start, the role patches the config file to set `initial-cluster-state: existing` so that subsequent Ansible runs do not attempt to re-bootstrap the cluster.
