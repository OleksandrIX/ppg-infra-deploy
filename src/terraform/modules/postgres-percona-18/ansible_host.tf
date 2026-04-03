resource "azurerm_network_interface" "ansible_host_nic" {
  count               = var.create_ansible_host ? 1 : 0
  name                = "${var.ansible_host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.subnet_prefix, var.ansible_host_private_ip_hostnumber)
  }
}

resource "azurerm_linux_virtual_machine" "ansible_host" {
  count               = var.create_ansible_host ? 1 : 0
  name                = var.ansible_host_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.ansible_host_vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.ansible_host_nic[0].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
