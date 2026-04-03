variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-ppg-cluster-dev"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "polandcentral"
}

variable "vnet" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "database_subnet" {
  description = "Database subnet address space"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "jumpbox_subnet" {
  description = "Jumpbox subnet address space"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "admin_username" {
  description = "Administrator username for all virtual machines"
  type        = string
  default     = "oleksandrix"
}

variable "ssh_pub_key_path" {
  description = "Path to the public SSH key for VM access"
  type        = string
  default     = "~/.ssh/azure-ppg-cluster.pub"
}

variable "vm_count" {
  description = "Number of VMs to create in the database cluster"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "Size of the virtual machines (e.g., Standard_D2s_v5)"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "vm_name_prefix" {
  description = "Prefix for the virtual machine names"
  type        = string
}

variable "admin_ip" {
  description = "My public IP address for SSH access to Jumpbox"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for pgBackRest repository"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container for pgBackRest repository"
  type        = string
}

variable "create_data_disk" {
  description = "Whether to create an additional disk for the database cluster (true/false)"
  type        = bool
  default     = false
}

variable "data_disk_size_gb" {
  description = "Size of the additional data disk in GB (applicable if create_data_disk is true)"
  type        = number
  default     = 64
}

variable "database_lb_private_ip" {
  description = "Static private IP address for the internal Azure load balancer"
  type        = string
}

variable "database_lb_rules" {
  description = "Map of internal load balancer rules keyed by logical rule name"
  type = map(object({
    frontend_port           = number
    backend_port            = optional(number)
    protocol                = optional(string)
    probe_port              = optional(number)
    probe_protocol          = optional(string)
    probe_request_path      = optional(string)
    idle_timeout_in_minutes = optional(number)
    disable_outbound_snat   = optional(bool)
  }))

  default = {
    primary = {
      frontend_port      = 5000
      backend_port       = 6432
      probe_port         = 8008
      probe_protocol     = "Http"
      probe_request_path = "/primary"
    }
    replica = {
      frontend_port      = 5001
      backend_port       = 6432
      probe_port         = 8008
      probe_protocol     = "Http"
      probe_request_path = "/replica"
    }
  }
}

variable "database_lb_probe_interval_in_seconds" {
  description = "Health probe interval for the internal load balancer"
  type        = number
  default     = 5
}

variable "database_lb_number_of_probes" {
  description = "Number of failed probes before marking a backend unhealthy"
  type        = number
  default     = 2
}
