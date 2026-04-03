output "load_balancer_id" {
  description = "ID of the Azure load balancer"
  value       = azurerm_lb.ppg_internal_lb.id
}
