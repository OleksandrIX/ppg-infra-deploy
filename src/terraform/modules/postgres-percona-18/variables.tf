variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the Azure virtual machines"
  type        = string
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
}

variable "vm_name_prefix" {
  description = "Prefix for the virtual machine names"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
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

variable "subnet_prefix" {
  description = "CIDR prefix for the subnet (e.g., 10.0.1.0/24) for generating static IPs"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machines (e.g., Standard_D2s_v5)"
  type    = string
  default = "Standard_D2s_v5"
}

variable "create_data_disk" {
  description = "Whether to create an additional disk for the database cluster (true/false)"
  type        = bool
  default     = false
}

variable "data_disk_size_gb" {
  description = "Size of the additional data disk in GB (applicable if create_data_disk is true)"
  type    = number
  default = 64
}

variable "vnet_id" {
  description = "Virtual network ID used by the load balancer backend pool"
  type        = string
}

variable "lb_name" {
  description = "Name of the internal Azure load balancer"
  type        = string
}

variable "lb_frontend_private_ip_address" {
  description = "Static private IP address assigned to the load balancer frontend"
  type        = string
}

variable "lb_frontend_configuration_name" {
  description = "Name of the LB frontend IP configuration"
  type        = string
  default     = "private-frontend"
}

variable "lb_sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "Standard"
}

variable "lb_rules" {
  description = "Map of load balancer rules keyed by logical rule name"
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

  validation {
    condition     = length(var.lb_rules) > 0
    error_message = "At least one load balancer rule must be provided."
  }
}

variable "lb_probe_interval_in_seconds" {
  description = "Interval between health probe attempts"
  type        = number
  default     = 5
}

variable "lb_number_of_probes" {
  description = "How many failed probes mark a backend as unhealthy"
  type        = number
  default     = 2
}
