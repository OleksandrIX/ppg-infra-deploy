resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = var.nic_ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = cidrhost(var.subnet_prefix, count.index + var.vm_private_ip_host_offset)
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-vm-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags
  zone                = tostring((count.index % 3) + 1)

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
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

resource "azurerm_managed_disk" "data_disk" {
  count                = var.create_data_disk ? var.vm_count : 0
  name                 = "${var.vm_name_prefix}-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_account_type
  create_option        = var.data_disk_create_option
  disk_size_gb         = var.data_disk_size_gb
  zone                 = tostring((count.index % 3) + 1)
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_attach" {
  count              = var.create_data_disk ? var.vm_count : 0
  managed_disk_id    = azurerm_managed_disk.data_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[count.index].id
  lun                = var.data_disk_attachment_lun
  caching            = var.data_disk_attachment_caching
}
