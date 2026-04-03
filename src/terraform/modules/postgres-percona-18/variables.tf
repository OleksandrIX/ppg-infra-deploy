variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Region name (e.g., eastus, westus2)"
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VM network interfaces"
  type        = string
}

variable "subnet_prefix" {
  description = "CIDR prefix for the subnet (e.g., 10.0.1.0/24) for generating static IPs"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 3
}

variable "vm_name_prefix" {
  description = "Prefix for the virtual machine names"
  type        = string
  default     = "percona-node"
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for the virtual machines"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the virtual machines"
  type        = map(string)
  default     = {}
}

variable "ansible_host" {
  description = "Dedicated host configuration for running Ansible deployment"
  type = object({
    create                = bool
    name                  = string
    vm_size               = string
    private_ip_hostnumber = number
  })

  default = {
    create                = true
    name                  = "percona-ansible-host"
    vm_size               = "Standard_B2s"
    private_ip_hostnumber = 250
  }
}

variable "cluster_vm" {
  description = "Cluster VM configuration"
  type = object({
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

variable "data_disk" {
  description = "Additional data disk configuration for cluster VMs"
  type = object({
    create               = bool
    storage_account_type = string
    create_option        = string
    size_gb              = number
    attachment_lun       = number
    attachment_caching   = string
  })

  default = {
    create               = false
    storage_account_type = "Premium_LRS"
    create_option        = "Empty"
    size_gb              = 64
    attachment_lun       = 10
    attachment_caching   = "ReadOnly"
  }

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "PremiumV2_LRS", "Premium_ZRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.data_disk.storage_account_type)
    error_message = "data_disk.storage_account_type must be one of: Standard_LRS, StandardSSD_ZRS, Premium_LRS, PremiumV2_LRS, Premium_ZRS, StandardSSD_LRS, UltraSSD_LRS."
  }
}

variable "lb" {
  description = "Internal load balancer configuration"
  type = object({
    name                          = string
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
    name                          = "ppg-internal-lb"
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
