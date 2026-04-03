variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
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

variable "container_access_type" {
  type        = string
  default     = "private"
  description = "Access level for the storage container"
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

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is enabled for the storage account"
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "Whether nested items can be public in the storage account"
}

variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "Minimum TLS version for the storage account"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the resources"
}
