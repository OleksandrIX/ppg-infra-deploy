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

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-ppg-cluster"
}

variable "database_subnet" {
  description = "Database subnet address space"
  type        = list(string)
}

variable "database_subnet_name" {
  description = "Database subnet name"
  type        = string
  default     = "snet-database"
}
