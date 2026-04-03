output "storage_account_name" {
  value       = azurerm_storage_account.sa.name
  description = "Storage Account name"
}

output "storage_account_primary_key" {
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
  description = "Primary access key for the Storage Account"
}

output "storage_container_name" {
  value       = azurerm_storage_container.sc.name
  description = "Storage Container name"
}

output "storage_container_id" {
  value       = azurerm_storage_container.sc.id
  description = "Storage Container resource ID"
}
