variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "name" {
  description = "Name of the Azure load balancer"
  type        = string
}

variable "frontend_configuration_name" {
  description = "Name of the LB frontend IP configuration"
  type        = string
  default     = "private-frontend"
}

variable "sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "Standard"
}

variable "backend_vnet_id" {
  description = "Virtual network ID used by the load balancer backend pool"
  type        = string
}

variable "frontend_subnet_id" {
  description = "Subnet ID used by the load balancer frontend IP configuration"
  type        = string
}

variable "frontend_private_ip_address" {
  description = "Static private IP address assigned to the load balancer frontend"
  type        = string
}

variable "backend_ip_addresses" {
  description = "Private IP addresses of backend nodes"
  type        = list(string)

  validation {
    condition     = length(var.backend_ip_addresses) > 0
    error_message = "At least one backend IP address must be provided."
  }
}

variable "rules" {
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
    condition     = length(var.rules) > 0
    error_message = "At least one load balancer rule must be provided."
  }
}

variable "probe_interval_in_seconds" {
  description = "Interval between health probe attempts"
  type        = number
  default     = 5
}

variable "number_of_probes" {
  description = "How many failed probes mark a backend as unhealthy"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to the load balancer resources"
  type        = map(string)
  default     = {}
}
