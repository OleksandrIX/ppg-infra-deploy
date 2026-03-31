resource "azurerm_storage_account" "pgbackrest_sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "pgbackrest_repo" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.pgbackrest_sa.id
  container_access_type = "private"
}
