variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "polandcentral"
}

variable "clusters" {
  description = "Cluster foundation definitions keyed by cluster name"
  type = map(object({
    resource_group_name              = string
    vnet_name                        = string
    vnet_address_space               = list(string)
    database_subnet_name             = string
    database_subnet_prefixes         = list(string)
    bastion_subnet_prefixes          = list(string)
    storage_account_name             = string
    nat_public_ip_name               = string
    nat_gateway_name                 = string
    bastion_public_ip_name           = string
    bastion_host_name                = string
    key_vault_name                   = string
    pgbackrest_container_name        = optional(string, "pgbackrest-repo")
    tfstate_container_name           = optional(string, "tfstate")
    pgbackrest_container_access_type = optional(string, "private")
    tfstate_container_access_type    = optional(string, "private")
    account_tier                     = optional(string, "Standard")
    replication_type                 = optional(string, "LRS")
    public_network_access_enabled    = optional(bool, true)
    allow_nested_items_to_be_public  = optional(bool, false)
    min_tls_version                  = optional(string, "TLS1_2")
    key_vault_sku                    = optional(string, "standard")
  }))
}

variable "additional_key_vault_object_ids" {
  description = "Additional Azure AD object IDs that need Key Vault secret permissions (e.g., pipeline runners)"
  type        = list(string)
  default     = []
}
