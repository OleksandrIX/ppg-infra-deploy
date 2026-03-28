# ppg-infra-deploy

Infrastructure and configuration repository for provisioning a Percona PostgreSQL high-availability cluster with Terraform and Ansible.

## Overview

The repository is split into two main parts:

- `terraform/` provisions Azure infrastructure such as the resource group, virtual network, jumpbox, database VMs, and backup storage.
- `ansible/` configures the hosts into a working PostgreSQL HA stack built from Percona PostgreSQL, etcd, Patroni, pgBackRest, and PgBouncer.

## Repository Layout

| Path | Description |
|---|---|
| `ansible/` | Ansible configuration, inventories, playbooks, and roles |
| `terraform/environments/dev/` | Azure development environment entrypoint |
| `terraform/modules/` | Reusable Terraform modules for compute, network, and storage |

## Documentation

- Ansible documentation: [ansible/README.md](ansible/README.md)
- Terraform entrypoint: `terraform/environments/dev/`

## Terraform

The development environment in `terraform/environments/dev/` creates:

- one Azure resource group
- one virtual network with database and jumpbox subnets
- one jumpbox VM with a public IP
- three PostgreSQL nodes with attached data disks
- one Azure storage account and container for pgBackRest

Typical workflow:

```bash
cd terraform/environments/dev
terraform init
terraform plan -var "admin_ip=<your-public-ip>"
terraform apply -var "admin_ip=<your-public-ip>"
```

## Notes

- Ansible-specific setup, inventories, playbooks, and role documentation are described in [ansible/README.md](ansible/README.md).
- The repository currently contains a checked-in `terraform.tfstate` under `terraform/environments/dev/`; if that is intentional, keep it controlled carefully.

