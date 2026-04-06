data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subnet" "postgres_percona_subnet" {
  name                 = var.postgres_percona_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_key_vault" "postgres_percona_key_vault" {
  name                = var.postgres_percona_key_vault_name
  resource_group_name = var.resource_group_name
}

module "database_cluster" {
  source = "../../../src/terraform/modules/postgres-percona-18"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.postgres_percona_subnet.id
  subnet_prefix       = data.azurerm_subnet.postgres_percona_subnet.address_prefixes[0]
  admin_username      = var.postgres_percona_admin_username
  key_vault_id        = data.azurerm_key_vault.postgres_percona_key_vault.id

  cluster_vm   = var.postgres_percona_cluster_vm
  ansible_host = var.postgres_percona_ansible_host
  data_disks   = var.postgres_percona_data_disks
  lb           = var.postgres_percona_lb

  cluster_vm_name_prefix = local.postgres_percona_cluster_vm_name_prefix
  ansible_host_name      = local.postgres_percona_ansible_host_name
  lb_name                = local.postgres_percona_lb_name

  ansible_source_dir  = local.ansible_source_dir
  ansible_env_dir     = local.ansible_env_dir
  wrapper_script_path = local.wrapper_script_path

  run_ansible_on_apply = var.postgres_percona_run_ansible_on_apply

  depends_on = [
    azurerm_key_vault_access_policy.terraform_runner,
  ]
}
