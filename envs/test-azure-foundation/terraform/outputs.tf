output "bastion_public_ip" {
  description = "Azure Bastion public IP"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "nat_gateway_public_ip" {
  description = "NAT gateway public IP used for subnet outbound"
  value       = azurerm_public_ip.nat_pip.ip_address
}
