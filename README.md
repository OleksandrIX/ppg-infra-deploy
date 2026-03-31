# ppg-infra-deploy

Infrastructure and configuration repository for provisioning a Percona PostgreSQL high-availability cluster with Terraform and Ansible.

## Overview

The repository is split into two layers:

- `src/` contains reusable source code (Ansible roles/playbooks/config and Terraform modules).
- `envs/` contains environment entrypoints (variables, inventories, and Terraform root modules) that consume code from `src/`.

## Repository Layout

| Path | Description |
|---|---|
| `src/ansible/` | Shared Ansible code: `ansible.cfg`, playbooks, and roles |
| `src/terraform/modules/` | Shared Terraform modules: `network`, `compute`, `storage` |
| `envs/test-azure/` | Azure-backed environment entrypoint (Terraform + Ansible inventory/group vars) |
| `envs/test-selfh/` | Self-hosted/testing environment entrypoint |

## Documentation

- Ansible documentation: [src/ansible/README.md](src/ansible/README.md)
- Terraform modules: [src/terraform/modules](src/terraform/modules)

## Terraform

The Azure environment in `envs/test-azure/terraform/` creates:

- one Azure resource group
- one virtual network with database and jumpbox subnets
- one jumpbox VM with a public IP
- three PostgreSQL nodes with attached data disks
- one Azure storage account and container for pgBackRest

Typical workflow:

```bash
cd envs/test-azure/terraform
terraform init
terraform plan -var "admin_ip=<your-public-ip>"
terraform apply -var "admin_ip=<your-public-ip>"
```

Module sources in environment Terraform files point to `src/terraform/modules/*`.

## Ansible

Environment-specific Ansible data is stored under `envs/<environment>/ansible/` (inventory/group vars/databases), while shared automation logic remains in `src/ansible/`.

Typical workflow after infrastructure is ready:

```bash
cd src/ansible
ansible-playbook -i ../../envs/test-azure/ansible/inventory_azure_rm.yml playbooks/create-pgg-cluster.yml
```

## Notes

- Ansible role/playbook details are described in [src/ansible/README.md](src/ansible/README.md).
- Keep environment secrets in Vault files under `envs/<environment>/ansible/group_vars/**/vault.yml`.

