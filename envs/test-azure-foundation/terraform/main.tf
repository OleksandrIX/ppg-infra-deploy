resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source               = "../../../src/terraform/modules/network"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  vnet                 = var.vnet
  vnet_name            = var.vnet_name
  database_subnet      = var.database_subnet
  database_subnet_name = var.database_subnet_name
}

module "pgbackrest_storage" {
  source                          = "../../../src/terraform/modules/storage"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  storage_account_name            = var.storage_account_name
  container_name                  = var.container_name
  container_access_type           = var.container_access_type
  account_tier                    = var.account_tier
  replication_type                = var.replication_type
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  min_tls_version                 = var.min_tls_version
}
