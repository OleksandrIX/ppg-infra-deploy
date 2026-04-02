output "vm_details" {
  description = "Map of VM names to network details"
  value = {
    for i in range(var.vm_count) :
    azurerm_linux_virtual_machine.vm[i].name => {
      private_ip = azurerm_network_interface.nic[i].private_ip_address
      public_ip  = try(azurerm_public_ip.pip[i].ip_address, null)
    }
  }
}

output "vm_identity_principal_ids" {
  description = "Map of VM names to system-assigned managed identity principal IDs"
  value = {
    for i in range(var.vm_count) :
    azurerm_linux_virtual_machine.vm[i].name => try(azurerm_linux_virtual_machine.vm[i].identity[0].principal_id, null)
  }
}
