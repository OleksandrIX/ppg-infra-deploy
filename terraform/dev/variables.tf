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
