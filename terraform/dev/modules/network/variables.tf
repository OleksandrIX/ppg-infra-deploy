variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "vnet" {
  description = "Virtual network address space for the Azure resources"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_database" {
  description = "Database subnet address space for the Azure resources"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
