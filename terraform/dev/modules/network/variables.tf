variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "vnet" {
  description = "Virtual network address space"
  type        = list(string)
}

variable "database_subnet" {
  description = "Database subnet address space"
  type        = list(string)
}

variable "jumpbox_subnet" {
  description = "Jumpbox subnet address space"
  type        = list(string)
}

variable "admin_ip" {
  description = "Allowed IP address for SSH access"
  type        = string
}
