# Terraform variables for test-azure environment
resource_group_name = "rg-ppg-cluster-dev"
environment         = "test-azure"

# Existing network values provided externally
virtual_network_name         = "vnet-ppg-cluster"
postgres_percona_subnet_name = "snet-database"

# Admin credentials
admin_username = "oleksandrix"

# Key Vault name (created by foundation)
key_vault_name = "kv-ppg-cluster-dev"

# Ansible source and environment directories
ansible_source_dir = "${path.module}/../../../src/ansible"
ansible_env_dir    = "${path.module}/../ansible"

# Ansible host settings
ansible_host = {
  create                = true
  name                  = "percona-ansible-host"
  vm_size               = "Standard_D2s_v4"
  private_ip_hostnumber = 250
}

# Cluster VM settings
cluster_vm = {
  count                         = 3
  name_prefix                   = "percona-node"
  size                          = "Standard_D2s_v4"
  nic_ip_configuration_name     = "internal"
  private_ip_address_allocation = "Static"
  private_ip_host_offset        = 10
  zones                         = ["1", "2", "3"]

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Data disks for pgdata LVM volume group
data_disks = [
  {
    storage_account_type = "Premium_ZRS"
    create_option        = "Empty"
    size_gb              = 128
    lun                  = 10
    caching              = "ReadOnly"
  },
]

# Internal load balancer settings
lb = {
  name                          = "ppg-internal-lb"
  frontend_private_ip_address   = "10.0.1.100"
  frontend_configuration_name   = "private-frontend"
  sku                           = "Standard"
  private_ip_address_allocation = "Static"
  probe_interval_in_seconds     = 5
  number_of_probes              = 2
  default_protocol              = "Tcp"
  default_idle_timeout_minutes  = 4
  default_disable_outbound_snat = false

  rules = {
    postgres = {
      frontend_port      = 5432
      backend_port       = 6432
      probe_port         = 8008
      probe_protocol     = "Http"
      probe_request_path = "/primary"
    }
  }
}
