
locals {
  environment       = "test-azure"
  jumpbox_ip        = one(values(module.jumpbox.vm_details)).public_ip
  ssh_priv_key_path = pathexpand("~/.ssh/azure-ppg-cluster")
  proxy_common_args = "-o ProxyCommand=\"ssh -W %h:%p -q ${var.admin_username}@${local.jumpbox_ip}\" -o StrictHostKeyChecking=no"

  inventory_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../ansible/inventory", "**")) :
    filemd5("${path.module}/../ansible/inventory/${f}")
  ]))

  playbooks_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../../../src/ansible/playbooks", "**")) :
    filemd5("${path.module}/../../../src/ansible/playbooks/${f}")
  ]))
}

resource "terraform_data" "create_cluster" {
  depends_on = [
    module.database_cluster,
    module.pgbackrest_storage,
  ]

  triggers_replace = [
    sha1(jsonencode(module.database_cluster.vm_details)),
    sha1(jsonencode(module.jumpbox.vm_details)),
    local.inventory_hash,
    local.playbooks_hash,
    filemd5("${path.module}/../../../scripts/run-create-cluster.sh"),
  ]

  provisioner "local-exec" {
    working_dir = path.module

    command = <<-EOT
      set -eu
      "${path.module}/../../../scripts/run-create-cluster.sh" \
        "${local.environment}" \
        "${var.admin_username}" \
        "${local.jumpbox_ip}" \
        "${local.ssh_priv_key_path}" \
        "${pathexpand("~/.secrets/.ppg_cluster_vault_pass")}"
    EOT
  }
}
