# Exporters Role

Main role for managing Prometheus exporters installation and configuration.

## Sub-roles

- `node_exporter` - Prometheus Node Exporter for system metrics

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - exporters
```
