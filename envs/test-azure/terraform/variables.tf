variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-ppg-cluster-dev"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "virtual_network_name" {
  description = "Existing virtual network name where postgres subnet exists"
  type        = string
}

variable "postgres_percona_subnet_name" {
  description = "Existing subnet name for postgres-percona deployment"
  type        = string
}

variable "postgres_percona_admin_username" {
  description = "Administrator username for all virtual machines"
  type        = string
  default     = "oleksandrix"
}

variable "postgres_percona_key_vault_name" {
  description = "Azure Key Vault name where SSH keys are stored"
  type        = string
}

variable "postgres_percona_run_ansible_on_apply" {
  description = "Enable ansible wrapper execution on ansible-host during terraform apply"
  type        = bool
  default     = false
}

variable "postgres_percona_cluster_vm" {
  description = "Cluster VM configuration"
  type = object({
    count                         = number
    size                          = string
    nic_ip_configuration_name     = string
    private_ip_address_allocation = string
    private_ip_host_offset        = number
    zones                         = list(string)

    os_disk = object({
      caching              = string
      storage_account_type = string
    })

    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })

  default = {
    count                         = 3
    size                          = "Standard_D2s_v5"
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
}

variable "postgres_percona_ansible_host" {
  description = "Ansible deployment host configuration"
  type = object({
    create                = bool
    vm_size               = string
    private_ip_hostnumber = number
  })

  default = {
    create                = true
    vm_size               = "Standard_B2s"
    private_ip_hostnumber = 250
  }
}

variable "postgres_percona_data_disks" {
  description = "List of data disks to create per cluster VM"
  type = list(object({
    storage_account_type = string
    create_option        = string
    size_gb              = number
    lun                  = number
    caching              = string
  }))

  default = []
}

variable "postgres_percona_lb" {
  description = "Internal load balancer configuration"
  type = object({
    frontend_private_ip_address   = string
    frontend_configuration_name   = string
    sku                           = string
    private_ip_address_allocation = string
    probe_interval_in_seconds     = number
    number_of_probes              = number
    default_protocol              = string
    default_idle_timeout_minutes  = number
    default_disable_outbound_snat = bool

    rules = map(object({
      frontend_port           = number
      backend_port            = optional(number)
      protocol                = optional(string)
      probe_port              = optional(number)
      probe_protocol          = optional(string)
      probe_request_path      = optional(string)
      idle_timeout_in_minutes = optional(number)
      disable_outbound_snat   = optional(bool)
    }))
  })

  default = {
    frontend_private_ip_address   = "10.0.0.100"
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
}
