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

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-ppg-cluster"
}

variable "database_subnet" {
  description = "Database subnet address space"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "database_subnet_name" {
  description = "Database subnet name"
  type        = string
  default     = "snet-database"
}

variable "storage_account_name" {
  description = "Storage account name for pgBackRest"
  type        = string
}

variable "pgbackrest_container_name" {
  description = "Storage container name for pgBackRest"
  type        = string
  default     = "pgbackrest-repo"
}

variable "tfstate_container_name" {
  description = "Storage container name for Terraform remote state"
  type        = string
  default     = "tfstate"
}

variable "ansible_artifacts_container_name" {
  description = "Storage container name for Ansible artifacts"
  type        = string
  default     = "ansible-artifacts"
}

variable "pgbackrest_container_access_type" {
  description = "Access level for pgBackRest storage container"
  type        = string
  default     = "private"
}

variable "tfstate_container_access_type" {
  description = "Access level for Terraform state storage container"
  type        = string
  default     = "private"
}

variable "ansible_artifacts_container_access_type" {
  description = "Access level for Ansible artifacts storage container"
  type        = string
  default     = "private"
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "public_network_access_enabled" {
  description = "Enable public network access for storage account"
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public in storage account"
  type        = bool
  default     = false
}

variable "min_tls_version" {
  description = "Minimum TLS version for storage account"
  type        = string
  default     = "TLS1_2"
}

variable "bastion_subnet" {
  description = "Azure Bastion subnet address prefix (must be named AzureBastionSubnet, minimum /26)"
  type        = list(string)
  default     = ["10.0.2.0/26"]
}

variable "key_vault_name" {
  description = "Azure Key Vault name (must be globally unique)"
  type        = string
}

variable "key_vault_sku" {
  description = "Azure Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}
