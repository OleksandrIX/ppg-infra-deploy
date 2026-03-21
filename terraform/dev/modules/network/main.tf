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

resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "nsg-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.admin_ip
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.jumpbox_nsg.name
}


resource "azurerm_subnet_network_security_group_association" "jumpbox_nsg_assoc" {
  subnet_id                 = azurerm_subnet.jumpbox_subnet.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}
