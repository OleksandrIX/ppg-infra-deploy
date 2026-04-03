resource "azurerm_network_interface" "nic" {
  count = var.cluster_vm.count

  name                = "${var.cluster_vm.name_prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.cluster_vm.nic_ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.cluster_vm.private_ip_address_allocation
    private_ip_address            = cidrhost(var.subnet_prefix, count.index + var.cluster_vm.private_ip_host_offset)
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.cluster_vm.count

  name                = "${var.cluster_vm.name_prefix}-vm-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.cluster_vm.size
  admin_username      = var.admin_username
  zone                = var.cluster_vm.zones[count.index % length(var.cluster_vm.zones)]

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
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
}

resource "azurerm_managed_disk" "data_disk" {
  for_each = local.vm_data_disks

  name                 = "${var.cluster_vm.name_prefix}-data-${each.value.vm_index}-${each.value.disk_index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.config.storage_account_type
  create_option        = each.value.config.create_option
  disk_size_gb         = each.value.config.size_gb
  zone                 = contains(["Premium_ZRS", "StandardSSD_ZRS"], each.value.config.storage_account_type) ? null : var.cluster_vm.zones[each.value.vm_index % length(var.cluster_vm.zones)]
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_attach" {
  for_each = local.vm_data_disks

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[each.value.vm_index].id
  lun                = each.value.config.lun
  caching            = each.value.config.caching
}
