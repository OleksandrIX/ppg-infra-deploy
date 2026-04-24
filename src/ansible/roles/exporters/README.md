# Exporters Role

Main role for managing Prometheus exporters installation and configuration.

## Sub-roles

- `node_exporter` - Prometheus Node Exporter for system metrics

## Variables

### Optional
- `exporters_node_exporter_enabled`: Enable/disable Node Exporter installation (default: `true`)

### Node Exporter Variables

See [node_exporter README](roles/node_exporter/README.md) for detailed configuration options.

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - exporters
  vars:
    exporters_node_exporter_enabled: true
    node_exporter_port: 9100
```

## Supported Systems

- Linux (Debian, RHEL, Ubuntu, CentOS)
- Auto-detects system architecture (x86_64, ARM64)

