location = "polandcentral"

clusters = {
  pg16 = {
    resource_group_name = "rg-test-ppg-16"

    vnet_name                = "vnet-test-ppg-16"
    vnet_address_space       = ["10.16.0.0/16"]
    database_subnet_name     = "snet-database"
    database_subnet_prefixes = ["10.16.1.0/24"]
    bastion_subnet_prefixes  = ["10.16.2.0/26"]

    nat_public_ip_name = "pip-natgw-ppg-16"
    nat_gateway_name = "natgw-ppg-16"
    bastion_public_ip_name = "pip-bastion-ppg-16"
    bastion_host_name = "bastion-ppg-16"

    storage_account_name = "ppgclusterpgbackrest16"
    key_vault_name       = "kv-test-ppg-16"
  }

  pg18 = {
    resource_group_name = "rg-test-ppg-18"

    vnet_name                = "vnet-test-ppg-18"
    vnet_address_space       = ["10.18.0.0/16"]
    database_subnet_name     = "snet-database"
    database_subnet_prefixes = ["10.18.1.0/24"]
    bastion_subnet_prefixes  = ["10.18.2.0/26"]

    nat_public_ip_name = "pip-natgw-ppg-18"
    nat_gateway_name = "natgw-ppg-18"
    bastion_public_ip_name = "pip-bastion-ppg-18"
    bastion_host_name = "bastion-ppg-18"

    storage_account_name = "ppgclusterpgbackrest18"
    key_vault_name       = "kv-test-ppg-18"
  }
}

# Access policies for Key Vault
additional_key_vault_object_ids = [
  "8ad51a80-413d-46f2-8eec-40f2befe3739",
]

# Azure DevOps service connection principals (one per environment/cluster)
service_connection_object_ids = {
  pg16 = "77b74386-027d-4006-a7e1-cfae71d22112" # ppg-16
  pg18 = "aaff0cc7-b1e9-4761-9c13-1523ca318cba" # ppg-18
}
