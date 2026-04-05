resource "terraform_data" "prepare_ansible_bundle" {
  triggers_replace = {
    src_ansible_hash = sha1(join("", [
      for f in sort(fileset(var.ansible_source_dir, "**")) :
      filemd5("${var.ansible_source_dir}/${f}")
    ]))
    env_ansible_hash = sha1(join("", [
      for f in sort(local.ansible_env_files) :
      filemd5("${var.ansible_env_dir}/${f}")
    ]))
    inventory_hash = sha1(local.generated_inventory_content)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      rm -rf "${local.ansible_bundle_dir}"
      mkdir -p "${local.ansible_bundle_dir}"
      cp -a "${var.ansible_source_dir}/." "${local.ansible_bundle_dir}/"
      if [ -n "${var.ansible_env_dir}" ] && [ -d "${var.ansible_env_dir}" ]; then
        cp -a "${var.ansible_env_dir}/." "${local.ansible_bundle_dir}/"
      fi
      mkdir -p "${local.ansible_bundle_dir}/inventory"
    EOT
  }
}

resource "local_file" "generated_inventory" {
  filename   = "${local.ansible_bundle_dir}/inventory/hosts.yml"
  content    = local.generated_inventory_content
  depends_on = [terraform_data.prepare_ansible_bundle]
}

data "archive_file" "ansible_bundle_zip" {
  type        = "zip"
  source_dir  = local.ansible_bundle_dir
  output_path = "${local.generated_dir}/ansible-bundle.zip"

  depends_on = [local_file.generated_inventory]
}
