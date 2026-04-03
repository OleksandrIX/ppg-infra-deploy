resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source              = "../../../src/terraform/modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet                = var.vnet
  database_subnet     = var.database_subnet
  jumpbox_subnet      = var.jumpbox_subnet
  admin_ip            = var.admin_ip
}

module "pgbackrest_storage" {
  source               = "../../../src/terraform/modules/storage"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_name = var.storage_account_name
  container_name       = var.container_name
}

module "database_cluster" {
  source = "../../../src/terraform/modules/postgres-percona-18"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = module.network.database_subnet_id
  subnet_prefix       = var.database_subnet[0]
  admin_username      = var.admin_username
  ssh_public_key      = file(var.ssh_pub_key_path)

  cluster_vm   = var.cluster_vm
  ansible_host = var.ansible_host
  data_disks   = var.data_disks
  lb           = var.lb
}
