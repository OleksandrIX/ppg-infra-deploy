output "clusters" {
  description = "Foundation resources created per cluster"
  value = {
    for cluster_key, cluster in var.clusters : cluster_key => {
      resource_group_name   = azurerm_resource_group.rg[cluster_key].name
      resource_group_id     = azurerm_resource_group.rg[cluster_key].id
      vnet_name             = azurerm_virtual_network.vnet[cluster_key].name
      vnet_id               = azurerm_virtual_network.vnet[cluster_key].id
      database_subnet_name  = azurerm_subnet.database_subnet[cluster_key].name
      database_subnet_id    = azurerm_subnet.database_subnet[cluster_key].id
      storage_account_name  = azurerm_storage_account.sa[cluster_key].name
      storage_account_id    = azurerm_storage_account.sa[cluster_key].id
      pgbackrest_container  = azurerm_storage_container.sc[cluster_key].name
      tfstate_container     = azurerm_storage_container.tfstate[cluster_key].name
      key_vault_name        = azurerm_key_vault.kv[cluster_key].name
      key_vault_id          = azurerm_key_vault.kv[cluster_key].id
      bastion_public_ip     = azurerm_public_ip.bastion_pip[cluster_key].ip_address
      nat_gateway_public_ip = azurerm_public_ip.nat_pip[cluster_key].ip_address
    }
  }
}

output "bastion_public_ips" {
  description = "Azure Bastion public IPs keyed by cluster"
  value = {
    for cluster_key in keys(var.clusters) : cluster_key => azurerm_public_ip.bastion_pip[cluster_key].ip_address
  }
}

output "nat_gateway_public_ips" {
  description = "NAT gateway public IPs keyed by cluster"
  value = {
    for cluster_key in keys(var.clusters) : cluster_key => azurerm_public_ip.nat_pip[cluster_key].ip_address
  }
}
