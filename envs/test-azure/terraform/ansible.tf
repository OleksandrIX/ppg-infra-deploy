locals {
  jumpbox_ip        = one(values(module.jumpbox.vm_details)).public_ip
  ssh_priv_key_path = pathexpand("~/.ssh/azure-ppg-cluster")

  db_node_private_ips = [
    for vm_name in sort(keys(module.database_cluster.vm_details)) :
    module.database_cluster.vm_details[vm_name].private_ip
  ]

  inventory_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../ansible/inventory", "**")) :
    filemd5("${path.module}/../ansible/inventory/${f}")
  ]))

  playbooks_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../../../src/ansible/playbooks", "**")) :
    filemd5("${path.module}/../../../src/ansible/playbooks/${f}")
  ]))

  create_cluster_triggers = {
    cluster_vms = sha1(jsonencode(module.database_cluster.vm_details))
    jumpbox_vms = sha1(jsonencode(module.jumpbox.vm_details))
    inventory   = local.inventory_hash
    playbooks   = local.playbooks_hash
    run_script  = filemd5("${path.module}/../../../scripts/run-create-cluster.sh")
  }
}

resource "terraform_data" "create_cluster" {
  depends_on = [
    module.database_cluster,
    module.pgbackrest_storage,
    azurerm_role_assignment.pgbackrest_blob_data_contributor,
  ]

  triggers_replace = values(local.create_cluster_triggers)

  provisioner "local-exec" {
    working_dir = path.module

    environment = {
      PGBACKREST_AZURE_ACCOUNT   = module.pgbackrest_storage.storage_account_name
      PGBACKREST_AZURE_CONTAINER = module.pgbackrest_storage.storage_container_name
    }

    command = <<-EOT
      set -eu
      "${path.module}/../../../scripts/run-create-cluster.sh" \
        "${var.environment}" \
        "${var.admin_username}" \
        "${local.jumpbox_ip}" \
        "${local.ssh_priv_key_path}" \
        "${pathexpand("~/.secrets/.ppg_cluster_vault_pass")}" \
        "${join(",", local.db_node_private_ips)}"
    EOT
  }
}
