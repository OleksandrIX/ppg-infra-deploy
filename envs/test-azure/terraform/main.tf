data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

data "azurerm_subnet" "postgres_percona" {
  name                 = var.postgres_percona_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

module "database_cluster" {
  source = "../../../src/terraform/modules/postgres-percona-18"

  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  subnet_id           = data.azurerm_subnet.postgres_percona.id
  subnet_prefix       = data.azurerm_subnet.postgres_percona.address_prefixes[0]
  admin_username      = var.admin_username
  ssh_public_key      = file(var.ssh_pub_key_path)

  cluster_vm   = var.cluster_vm
  ansible_host = var.ansible_host
  data_disks   = var.data_disks
  lb           = var.lb
}
