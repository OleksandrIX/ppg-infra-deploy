# Common settings
resource_group_name = "rg-ppg-cluster-dev"
location            = "polandcentral"

# VNET settings
vnet      = ["10.0.0.0/16"]
vnet_name = "vnet-ppg-cluster"

# Subnet settings
database_subnet      = ["10.0.1.0/24"]
database_subnet_name = "snet-database"

# Storage settings
storage_account_name             = "ppgclusterpgbackrest2"
pgbackrest_container_name        = "pgbackrest-repo"
pgbackrest_container_access_type = "private"
tfstate_container_name           = "tfstate"
tfstate_container_access_type    = "private"
account_tier                     = "Standard"
replication_type                 = "LRS"
public_network_access_enabled    = true
allow_nested_items_to_be_public  = false
min_tls_version                  = "TLS1_2"
