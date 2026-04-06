variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Region name (e.g., eastus, westus2)"
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

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "azureuser"
}

variable "key_vault_id" {
  description = "Azure Key Vault ID where SSH keys will be stored"
  type        = string
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
    count                         = number
    name_prefix                   = string
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
    name_prefix                   = "percona-node"
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

  validation {
    condition     = var.cluster_vm.count > 0
    error_message = "cluster_vm.count must be greater than 0."
  }

  validation {
    condition     = length(var.cluster_vm.zones) > 0
    error_message = "cluster_vm.zones must contain at least one availability zone."
  }
}

variable "data_disks" {
  description = "List of data disks to create per cluster VM. Each disk has independent parameters. Empty list = no disks."
  type = list(object({
    storage_account_type = string
    create_option        = string
    size_gb              = number
    lun                  = number
    caching              = string
  }))

  default = []
  # data_disks = [
  #   {
  #     storage_account_type = "Premium_ZRS"
  #     create_option        = "Empty"
  #     size_gb              = 256
  #     lun                  = 10
  #     caching              = "ReadOnly"
  #   },
  # ]

  validation {
    condition = alltrue([
      for d in var.data_disks :
      contains(["Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "PremiumV2_LRS", "Premium_ZRS", "StandardSSD_LRS", "UltraSSD_LRS"], d.storage_account_type)
    ])
    error_message = "Each data_disks entry storage_account_type must be one of: Standard_LRS, StandardSSD_ZRS, Premium_LRS, PremiumV2_LRS, Premium_ZRS, StandardSSD_LRS, UltraSSD_LRS."
  }

  validation {
    condition     = alltrue([for d in var.data_disks : d.size_gb > 0])
    error_message = "Each data_disks entry size_gb must be greater than 0."
  }

  validation {
    condition     = alltrue([for d in var.data_disks : d.lun >= 10])
    error_message = "Each data_disks entry lun must be >= 10."
  }

  validation {
    condition     = length(distinct([for d in var.data_disks : d.lun])) == length(var.data_disks)
    error_message = "Each data_disks entry must have a unique lun value."
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

variable "ansible_env_dir" {
  description = "Optional environment-specific ansible files directory (e.g., containing group_vars)."
  type        = string
  default     = ""
}

variable "ansible_source_dir" {
  description = "Path to ansible source directory containing playbooks and roles"
  type        = string
  default     = ""
}

variable "wrapper_script_path" {
  description = "Path to run-create-cluster wrapper script that should be bundled"
  type        = string
  default     = ""
}

variable "run_ansible_on_apply" {
  description = "Execute run-create-cluster wrapper on ansible-host during terraform apply"
  type        = bool
  default     = true
}
