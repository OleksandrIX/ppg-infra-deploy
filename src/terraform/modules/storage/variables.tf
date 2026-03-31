variable "resource_group_name" {
  description = "Resource group name for the Azure resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "storage_account_name" {
  type        = string
  description = "Unique name for the Storage Account (must be globally unique)"
}

variable "container_name" {
  type        = string
  default     = "pgbackrest-repo"
  description = "Name of the container for backups"
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Performance tier of the Storage Account"
}

variable "replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication type (LRS, ZRS, GRS, etc.)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the resources"
}
