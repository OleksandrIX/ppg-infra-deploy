resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ppg-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "snet-database"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.database_subnet
}

resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = "snet-jumpbox"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.jumpbox_subnet
}
