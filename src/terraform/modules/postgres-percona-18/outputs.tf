output "vm_details" {
  description = "Map of VM names to network details"
  value = {
    for i in range(var.cluster_vm.count) :
    azurerm_linux_virtual_machine.vm[i].name => {
      private_ip = azurerm_network_interface.nic[i].private_ip_address
    }
  }
}
