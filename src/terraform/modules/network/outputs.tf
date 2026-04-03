output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "database_subnet_id" {
  value = azurerm_subnet.database_subnet.id
}
