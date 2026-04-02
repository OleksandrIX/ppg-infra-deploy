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

module "jumpbox" {
  source              = "../../../src/terraform/modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = module.network.jumpbox_subnet_id
  subnet_prefix       = var.jumpbox_subnet[0]

  assign_public_ip = true

  vm_count       = 1
  vm_name_prefix = "jumpbox"
  admin_username = var.admin_username
  ssh_public_key = file(var.ssh_pub_key_path)
  vm_size        = "Standard_D2s_v4"

  storage_container_id = module.pgbackrest_storage.storage_container_id

  tags = {
    AnsibleGroup = "jumpbox"
    Environment  = var.environment
  }
}

module "database_cluster" {
  source              = "../../../src/terraform/modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = module.network.database_subnet_id
  subnet_prefix       = var.database_subnet[0]

  assign_public_ip = false

  vm_count       = var.vm_count
  vm_name_prefix = var.vm_name_prefix
  admin_username = var.admin_username
  ssh_public_key = file(var.ssh_pub_key_path)
  vm_size        = var.vm_size

  create_data_disk  = var.create_data_disk
  data_disk_size_gb = var.create_data_disk ? var.data_disk_size_gb : 0

  storage_container_id = module.pgbackrest_storage.storage_container_id

  depends_on = [module.pgbackrest_storage]

  tags = {
    AnsibleGroup = "pg_nodes"
    Environment  = var.environment
  }
}
