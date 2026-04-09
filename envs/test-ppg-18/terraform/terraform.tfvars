# Terraform variables for test-azure environment
resource_group_name  = "rg-test-ppg-18"
environment          = "test-ppg-18"
virtual_network_name = "vnet-test-ppg-18"
storage_account      = "ppgclusterpgbackrest18"

# Existing network values provided externally
postgres_percona_subnet_name = "snet-database"

# Admin credentials
postgres_percona_admin_username = "postgresadmin"

# Key Vault name (created by foundation)
postgres_percona_key_vault_name = "kv-test-ppg-18"

# Toggle Ansible execution on terraform apply
postgres_percona_run_ansible_on_apply = true

# Azure blob container for pgBackRest
postgres_percona_pgbackrest_azure_container = "pgbackrest-repo"

# Ansible host VM settings
postgres_percona_ansible_host = {
  create                = true
  vm_size               = "Standard_D2s_v6"
  private_ip_hostnumber = 250
}

# Cluster VM settings
postgres_percona_cluster_vm = {
  count                  = 3
  size                   = "Standard_D2s_v6"
  private_ip_host_offset = 87
  zones                  = ["1", "2", "3"]
}

# Data disks for pgdata LVM volume group
postgres_percona_data_disks = [
  {
    storage_account_type = "Premium_ZRS"
    create_option        = "Empty"
    size_gb              = 128
    lun                  = 10
    caching              = "ReadOnly"
  },
]

# Internal load balancer settings
postgres_percona_lb = {
  frontend_private_ip_address = "10.18.1.100"
  frontend_configuration_name = "private-frontend"
  sku                         = "Standard"
}
