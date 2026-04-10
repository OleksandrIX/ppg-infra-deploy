resource "azurerm_resource_group" "rg" {
  for_each = var.clusters

  name     = each.value.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  for_each = var.clusters

  name                = each.value.vnet_name
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  address_space       = each.value.vnet_address_space
}

resource "azurerm_subnet" "database_subnet" {
  for_each = var.clusters

  name                 = each.value.database_subnet_name
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = each.value.database_subnet_prefixes
}

resource "azurerm_public_ip" "nat_pip" {
  for_each = var.clusters

  name                = each.value.nat_public_ip_name
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  for_each = var.clusters

  name                    = each.value.nat_gateway_name
  location                = azurerm_resource_group.rg[each.key].location
  resource_group_name     = azurerm_resource_group.rg[each.key].name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  for_each = var.clusters

  nat_gateway_id       = azurerm_nat_gateway.nat[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_pip[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "database_subnet_nat" {
  for_each = var.clusters

  subnet_id      = azurerm_subnet.database_subnet[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat[each.key].id
}

resource "azurerm_storage_account" "sa" {
  for_each = var.clusters

  name                     = each.value.storage_account_name
  resource_group_name      = azurerm_resource_group.rg[each.key].name
  location                 = azurerm_resource_group.rg[each.key].location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.replication_type

  public_network_access_enabled   = each.value.public_network_access_enabled
  allow_nested_items_to_be_public = each.value.allow_nested_items_to_be_public
  min_tls_version                 = each.value.min_tls_version
}

resource "azurerm_storage_container" "sc" {
  for_each = var.clusters

  name                  = each.value.pgbackrest_container_name
  storage_account_id    = azurerm_storage_account.sa[each.key].id
  container_access_type = each.value.pgbackrest_container_access_type
}

resource "azurerm_storage_container" "tfstate" {
  for_each = var.clusters

  name                  = each.value.tfstate_container_name
  storage_account_id    = azurerm_storage_account.sa[each.key].id
  container_access_type = each.value.tfstate_container_access_type
}

resource "azurerm_subnet" "bastion_subnet" {
  for_each = var.clusters

  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = each.value.bastion_subnet_prefixes
}

resource "azurerm_public_ip" "bastion_pip" {
  for_each = var.clusters

  name                = each.value.bastion_public_ip_name
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  for_each = var.clusters

  name                = each.value.bastion_host_name
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet[each.key].id
    public_ip_address_id = azurerm_public_ip.bastion_pip[each.key].id
  }
}

resource "azurerm_key_vault" "kv" {
  for_each = var.clusters

  name                = each.value.key_vault_name
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = each.value.key_vault_sku
}

resource "azurerm_key_vault_access_policy" "terraform_runner_additional" {
  for_each = local.key_vault_policies

  key_vault_id = azurerm_key_vault.kv[each.value.cluster_key].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_role_assignment" "service_connection_rg_contributor" {
  for_each = {
    for cluster_key, object_id in var.service_connection_object_ids : cluster_key => object_id
    if contains(keys(var.clusters), cluster_key)
  }

  scope                = azurerm_resource_group.rg[each.key].id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "service_connection_storage_blob_data_contributor" {
  for_each = {
    for cluster_key, object_id in var.service_connection_object_ids : cluster_key => object_id
    if contains(keys(var.clusters), cluster_key)
  }

  scope                = azurerm_storage_account.sa[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "me_kv_admin" {
  for_each = var.clusters

  scope                = azurerm_key_vault.kv[each.key].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_virtual_network_peering" "ppg16_to_ppg18" {
  name                      = "ppg16-to-ppg18"
  resource_group_name       = azurerm_resource_group.rg["pg16"].name
  virtual_network_name      = azurerm_virtual_network.vnet["pg16"].name
  remote_virtual_network_id = azurerm_virtual_network.vnet["pg18"].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "ppg18_to_ppg16" {
  name                      = "ppg18-to-ppg16"
  resource_group_name       = azurerm_resource_group.rg["pg18"].name
  virtual_network_name      = azurerm_virtual_network.vnet["pg18"].name
  remote_virtual_network_id = azurerm_virtual_network.vnet["pg16"].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
