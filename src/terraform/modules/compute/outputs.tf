output "vm_details" {
  description = "Map of VM names to their private IP addresses"
  value = {
    for i in range(var.vm_count) :
    azurerm_linux_virtual_machine.vm[i].name => azurerm_network_interface.nic[i].private_ip_address
  }
}
