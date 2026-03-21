resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ppg-cluster-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-database-dev"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_database
}
