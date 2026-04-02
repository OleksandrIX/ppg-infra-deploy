locals {
  jumpbox_ip        = one(values(module.jumpbox.vm_details)).public_ip
  ssh_priv_key_path = pathexpand("~/.ssh/azure-ppg-cluster")

  db_node_private_ips = [
    for vm_name in sort(keys(module.database_cluster.vm_details)) :
    module.database_cluster.vm_details[vm_name].private_ip
  ]

  ansible_hash = sha1(join("", concat(
    [
      for f in sort(fileset("${path.module}/../ansible/inventory", "**")) :
      filemd5("${path.module}/../ansible/inventory/${f}")
    ],
    [
      for f in sort(fileset("${path.module}/../../../src/ansible/playbooks", "**")) :
      filemd5("${path.module}/../../../src/ansible/playbooks/${f}")
    ],
    [
      for f in sort(fileset("${path.module}/../../../src/ansible/roles", "**")) :
      filemd5("${path.module}/../../../src/ansible/roles/${f}")
    ],
    [
      filemd5("${path.module}/../../../src/ansible/ansible.cfg")
    ]
  )))

  create_cluster_triggers = {
    cluster_vms = sha1(jsonencode(module.database_cluster.vm_details))
    jumpbox_vms = sha1(jsonencode(module.jumpbox.vm_details))
    ansible     = local.ansible_hash
    run_script  = filemd5("${path.module}/../../../scripts/run-create-cluster.sh")
  }
}

resource "terraform_data" "create_cluster" {
  depends_on = [
    module.database_cluster,
    module.pgbackrest_storage,
  ]

  triggers_replace = values(local.create_cluster_triggers)

  provisioner "local-exec" {
    working_dir = path.module

    environment = {
      VAULT_PASSWORD_FILES       = pathexpand("~/.secrets/.ppg_cluster_vault_pass")
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
        "${join(",", local.db_node_private_ips)}"
    EOT
  }
}
