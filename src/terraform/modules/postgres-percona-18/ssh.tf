resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "${var.cluster_vm.name_prefix}-ssh-private-key"
  value        = tls_private_key.ssh.private_key_pem
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "${var.cluster_vm.name_prefix}-ssh-public-key"
  value        = tls_private_key.ssh.public_key_openssh
  key_vault_id = var.key_vault_id
}
