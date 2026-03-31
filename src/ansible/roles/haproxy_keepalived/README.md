# haproxy_keepalived

Ansible role for installing and configuring `percona-haproxy` with `keepalived` on PostgreSQL cluster nodes.

The role exposes a floating VIP and routes traffic using Patroni health endpoints:

- port `5000` -> primary (read-write), checked via `/primary`
- port `5001` -> replicas (read-only), checked via `/replica`
- port `7000` -> HAProxy stats page

## Requirements

- Ansible collection `ansible.posix` (used for `sysctl`)
- Percona repository configured on target hosts (package `percona-haproxy` must be available)
- `keepalived` package available in OS repositories
- `curl` available on target hosts (used by `vrrp_script`)
- Patroni REST API reachable on `127.0.0.1:{{ haproxy_patroni_port }}`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `haproxy_vip` | `""` | Required floating VIP address |
| `haproxy_vip_interface` | `{{ ansible_default_ipv4.interface }}` | Network interface for VIP |
| `haproxy_vip_cidr` | `24` | VIP CIDR prefix length |
| `haproxy_primary_port` | `5000` | Frontend port for primary (RW) |
| `haproxy_replica_port` | `5001` | Frontend port for replicas (RO) |
| `haproxy_stats_port` | `7000` | HAProxy stats HTTP port |
| `haproxy_patroni_port` | `8008` | Patroni REST API port used for checks |
| `pgbouncer_port` | `6432` | PgBouncer backend port |
| `haproxy_stats_user` | `stats` | HAProxy stats basic auth username |
| `haproxy_stats_password` | `stats_password` | HAProxy stats basic auth password |
| `postgres_hosts` | `[]` | List of PostgreSQL node hostnames |
| `keepalived_vrrp_id` | `51` | VRRP virtual router ID |
| `keepalived_vrrp_password` | `vrrp_secret` | VRRP authentication password |
| `keepalived_base_priority` | `100` | Base VRRP priority |
| `keepalived_primary_weight` | `20` | Priority boost on Patroni primary |
| `keepalived_check_interval` | `2` | Health-check interval (seconds) |
| `keepalived_check_fall` | `2` | Consecutive failures before down |
| `keepalived_check_rise` | `2` | Consecutive successes before up |

## Required Inventory Variables

The role expects these values to be provided in inventory/group vars:

| Variable | Description |
|---|---|
| `haproxy_vip` | VIP address to assign via Keepalived |
| `postgres_hosts` | List/group of PostgreSQL nodes used to build HAProxy backends |

## Included Task Files

| File | Description |
|---|---|
| `haproxy.yml` | Configures sysctl, installs and configures `percona-haproxy` |
| `keepalived.yml` | Installs and configures `keepalived` |

## Installed Files

| Path | Description |
|---|---|
| `/etc/haproxy/haproxy.cfg` | Generated HAProxy configuration |
| `/etc/keepalived/keepalived.conf` | Generated Keepalived configuration |
| `/etc/logrotate.d/haproxy` | Logrotate config for HAProxy logs |
| `/etc/logrotate.d/keepalived` | Logrotate config for Keepalived logs |

## Directory Layout

| Path | Owner | Permissions | Description |
|---|---|---|---|
| `/var/log/haproxy` | `haproxy:adm` | `2755` | HAProxy log directory |
| `/etc/keepalived` | `root:root` | `0755` | Keepalived config directory |

## Networking

| Port | Protocol | Purpose |
|---|---|---|
| `5000` | TCP | Client traffic routed to Patroni primary |
| `5001` | TCP | Client traffic routed to Patroni replicas |
| `6432` | TCP | PgBouncer backend target on each PostgreSQL node |
| `7000` | TCP | HAProxy stats page |
| `8008` | TCP | Patroni REST API check target |

## Handlers

| Handler | Trigger | Action |
|---|---|---|
| `reload haproxy` | HAProxy config changed | Reloads `haproxy` service |
| `restart keepalived` | Keepalived config changed | Restarts `keepalived` service |

## Example Playbook

```yaml
- name: Configure HAProxy VIP for PostgreSQL cluster
  hosts: pg_nodes
  become: true
  vars:
    haproxy_vip: "10.0.1.100"
    haproxy_vip_interface: "eth0"
    haproxy_vip_cidr: 24
    postgres_hosts: "{{ groups['pg_nodes'] }}"
    keepalived_vrrp_id: 51
  roles:
    - role: haproxy_keepalived
```

## Notes

- The role enforces `net.ipv4.ip_nonlocal_bind=1` so HAProxy can bind VIP listeners on all nodes.
- Keepalived runs all nodes as `BACKUP` and uses Patroni `/primary` as the VRRP weight source, so VIP follows the current PostgreSQL primary.
- Override sensitive values such as `keepalived_vrrp_password` and `haproxy_stats_password` in Vault.
