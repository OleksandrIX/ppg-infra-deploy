resource "azurerm_network_interface" "ansible_host_nic" {
  count               = var.ansible_host.create ? 1 : 0
  name                = "${var.ansible_host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.cluster_vm.nic_ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.cluster_vm.private_ip_address_allocation
    private_ip_address            = cidrhost(var.subnet_prefix, var.ansible_host.private_ip_hostnumber)
  }
}

resource "azurerm_linux_virtual_machine" "ansible_host" {
  count               = var.ansible_host.create ? 1 : 0
  name                = var.ansible_host_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.ansible_host.vm_size
  admin_username      = var.admin_username
  custom_data         = base64encode(local.ansible_host_cloud_init)

  network_interface_ids = [
    azurerm_network_interface.ansible_host_nic[0].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = var.cluster_vm.os_disk.caching
    storage_account_type = var.cluster_vm.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.cluster_vm.image.publisher
    offer     = var.cluster_vm.image.offer
    sku       = var.cluster_vm.image.sku
    version   = var.cluster_vm.image.version
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  depends_on = [
    azurerm_key_vault_secret.ssh_public_key,
    azurerm_linux_virtual_machine.vm,
  ]
}
