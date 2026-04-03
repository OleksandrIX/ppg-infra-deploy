resource "azurerm_network_interface" "ansible_host_nic" {
  count               = var.create_ansible_host ? 1 : 0
  name                = "${var.ansible_host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = var.nic_ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
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
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}
