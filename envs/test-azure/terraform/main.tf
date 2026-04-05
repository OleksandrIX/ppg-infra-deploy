data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

data "azurerm_subnet" "postgres_percona" {
  name                 = var.postgres_percona_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_access_policy" "terraform_runner" {
  key_vault_id = data.azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

module "database_cluster" {
  source = "../../../src/terraform/modules/postgres-percona-18"

  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  subnet_id           = data.azurerm_subnet.postgres_percona.id
  subnet_prefix       = data.azurerm_subnet.postgres_percona.address_prefixes[0]
  admin_username      = var.admin_username
  key_vault_id        = data.azurerm_key_vault.kv.id

  cluster_vm   = var.cluster_vm
  ansible_host = var.ansible_host
  data_disks   = var.data_disks
  lb           = var.lb

  ansible_source_dir  = "${path.module}/../../../src/ansible"
  ansible_env_dir = "${path.module}/../ansible"

  depends_on = [
    azurerm_key_vault_access_policy.terraform_runner,
  ]
}
