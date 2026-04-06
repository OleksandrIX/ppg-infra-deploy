resource "azurerm_virtual_machine_run_command" "run_create_cluster" {
  count = var.ansible_host.create && var.run_ansible_on_apply ? 1 : 0

  name               = "run-create-cluster"
  location           = var.location
  virtual_machine_id = azurerm_linux_virtual_machine.ansible_host[0].id

  source {
    script = templatefile("${path.module}/templates/run-create-cluster-on-ansible-host.sh.tftpl", {
      admin_username           = var.admin_username
      bundle_hash              = sha1(join("", [
        data.external.ansible_bundle_xz.result.archive_b64,
        data.external.ansible_bundle_xz.result.bundle_template_hash
      ]))
      ansible_bundle_xz_b64    = data.external.ansible_bundle_xz.result.archive_b64
      ssh_private_key_pem      = tls_private_key.ssh.private_key_pem
      ansible_secret_vars_json = local.ansible_secret_vars_json
      db_node_private_ips_csv  = join(",", local.db_node_private_ips)
      vm_name_prefix           = var.cluster_vm.name_prefix
    })
  }

  lifecycle {
    precondition {
      condition     = !var.run_ansible_on_apply || length(trimspace(var.pgbackrest_azure_key)) > 0
      error_message = "pgbackrest_azure_key must be provided when run_ansible_on_apply is enabled."
    }
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm,
    azurerm_virtual_machine_data_disk_attachment.data_attach,
    azurerm_linux_virtual_machine.ansible_host,
    # azurerm_key_vault_secret.psql_superuser_password,
    # azurerm_key_vault_secret.psql_replication_password,
    # azurerm_key_vault_secret.pgbouncer_auth_password,
    # azurerm_key_vault_secret.patroni_restapi_password,
    # azurerm_key_vault_secret.pgbackrest_cipher_pass,
    # azurerm_key_vault_secret.pgbackrest_azure_key,
  ]
}
