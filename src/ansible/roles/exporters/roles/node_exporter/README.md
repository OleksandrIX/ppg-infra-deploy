# Node Exporter Role

Installs and configures Prometheus Node Exporter for collecting system metrics.

## Features

- Downloads and installs node_exporter from official GitHub releases
- Auto-detects system architecture (x86_64, arm64, etc.)
- Creates dedicated system user and service directories
- Deploys systemd service with security hardening
- Verifies service health after installation

## Variables

### Required
None - all variables have sensible defaults.

### Optional
- `node_exporter_version`: Node Exporter release version (default: `1.11.1`)
- `node_exporter_port`: Service listening port (default: `9100`)
- `node_exporter_user`: System user for node_exporter service (default: `node_exporter`)
- `node_exporter_group`: System group for node_exporter service (default: `node_exporter`)
- `node_exporter_additional_options`: Additional command-line options (default: empty)

## Handlers

- `Restart node_exporter` - Restarts the node_exporter systemd service
- `Reload node_exporter` - Reloads the node_exporter systemd service

## Example Usage

As a sub-role of `exporters`:

```yaml
- hosts: all
  roles:
    - exporters
  vars:
    exporters_node_exporter_enabled: true
    node_exporter_version: "1.11.1"
    node_exporter_port: 9100
    node_exporter_additional_options: "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($|/)"
```

## Metrics

Node Exporter provides system metrics including:
- CPU usage and load
- Memory and swap utilization
- Disk space and I/O operations
- Network interface statistics
- File descriptor usage
- System uptime
- Custom metrics from textfile collector

## Dependencies

None - role is self-contained and handles all dependencies.

