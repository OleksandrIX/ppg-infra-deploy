output "storage_account_name" {
  value       = azurerm_storage_account.pgbackrest_sa.name
  description = "Storage Account name"
}

output "storage_account_primary_key" {
  value       = azurerm_storage_account.pgbackrest_sa.primary_access_key
  sensitive   = true
  description = "Primary access key for the Storage Account"
}

output "storage_container_name" {
  value       = azurerm_storage_container.pgbackrest_repo.name
  description = "Storage Container name"
}
