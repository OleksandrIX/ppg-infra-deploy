resource "random_password" "psql_superuser_password" {
  length  = 48
  special = false
}

resource "random_password" "psql_replication_password" {
  length  = 48
  special = false
}

resource "random_password" "pgbouncer_auth_password" {
  length  = 48
  special = false
}

resource "random_password" "patroni_restapi_password" {
  length  = 48
  special = false
}

resource "random_password" "pgbackrest_cipher_pass" {
  length  = 48
  special = false
}

resource "azurerm_key_vault_secret" "psql_superuser_password" {
  name         = "${var.cluster_vm_name_prefix}-psql-superuser-password"
  value        = random_password.psql_superuser_password.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "psql_replication_password" {
  name         = "${var.cluster_vm_name_prefix}-psql-replication-password"
  value        = random_password.psql_replication_password.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "pgbouncer_auth_password" {
  name         = "${var.cluster_vm_name_prefix}-pgbouncer-auth-password"
  value        = random_password.pgbouncer_auth_password.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "patroni_restapi_password" {
  name         = "${var.cluster_vm_name_prefix}-patroni-restapi-password"
  value        = random_password.patroni_restapi_password.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "pgbackrest_cipher_pass" {
  name         = "${var.cluster_vm_name_prefix}-pgbackrest-cipher-pass"
  value        = random_password.pgbackrest_cipher_pass.result
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "pgbackrest_azure_key" {
  name         = "${var.cluster_vm_name_prefix}-pgbackrest-azure-key"
  key_vault_id = var.key_vault_id
}
