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

variable "postgres_percona_ansible_host" {
  description = "Ansible deployment host configuration"
  type = object({
    create                        = optional(bool, true)
    vm_size                       = optional(string, "Standard_B2s")
    private_ip_hostnumber         = optional(number, 250)
    nic_ip_configuration_name     = optional(string, "internal")
    private_ip_address_allocation = optional(string, "Static")

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
    }), {})

    image = optional(object({
      publisher = optional(string, "Canonical")
      offer     = optional(string, "ubuntu-24_04-lts")
      sku       = optional(string, "server")
      version   = optional(string, "latest")
    }), {})
  })

  default = {
    create                        = true
    vm_size                       = "Standard_B2s"
    private_ip_hostnumber         = 250
    nic_ip_configuration_name     = "internal"
    private_ip_address_allocation = "Static"

    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }

    image = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
  }
}

variable "postgres_percona_cluster_vm" {
  description = "Cluster VM configuration"
  type = object({
    count                         = optional(number, 3)
    size                          = optional(string, "Standard_D2s_v5")
    nic_ip_configuration_name     = optional(string, "internal")
    private_ip_address_allocation = optional(string, "Static")
    private_ip_host_offset        = optional(number, 10)
    zones                         = optional(list(string), ["1", "2", "3"])

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
    }), {})

    image = optional(object({
      publisher = optional(string, "Canonical")
      offer     = optional(string, "ubuntu-24_04-lts")
      sku       = optional(string, "server")
      version   = optional(string, "latest")
    }), {})
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
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
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
    frontend_configuration_name   = optional(string, "private-frontend")
    sku                           = optional(string, "Standard")
    private_ip_address_allocation = optional(string, "Static")
    probe_interval_in_seconds     = optional(number, 5)
    number_of_probes              = optional(number, 2)
    default_protocol              = optional(string, "Tcp")
    default_idle_timeout_minutes  = optional(number, 4)
    default_disable_outbound_snat = optional(bool, false)

    rules = optional(map(object({
      frontend_port           = number
      backend_port            = optional(number)
      protocol                = optional(string)
      probe_port              = optional(number)
      probe_protocol          = optional(string)
      probe_request_path      = optional(string)
      idle_timeout_in_minutes = optional(number)
      disable_outbound_snat   = optional(bool)
      })), {
      postgres = {
        frontend_port      = 5432
        backend_port       = 6432
        probe_port         = 8008
        probe_protocol     = "Http"
        probe_request_path = "/primary"
      }
    })
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
