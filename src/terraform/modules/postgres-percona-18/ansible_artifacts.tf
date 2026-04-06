data "external" "ansible_bundle_xz" {
  query = {
    src_ansible_hash = sha1(join("", [
      for f in sort(fileset(var.ansible_source_dir, "**")) :
      filemd5("${var.ansible_source_dir}/${f}")
    ]))
    env_ansible_hash = sha1(join("", [
      for f in sort(local.ansible_env_files) :
      filemd5("${var.ansible_env_dir}/${f}")
    ]))
    inventory_hash = sha1(local.generated_inventory_content)
    bundle_template_hash = filemd5("${path.module}/templates/build-ansible-bundle.sh.tftpl")
  }

  program = [
    "bash",
    "-lc",
    templatefile("${path.module}/templates/build-ansible-bundle.sh.tftpl", {
      ansible_source_dir          = var.ansible_source_dir
      ansible_env_dir             = var.ansible_env_dir
      generated_inventory_content = local.generated_inventory_content
      wrapper_script_path         = var.wrapper_script_path
      bundle_template_hash        = filemd5("${path.module}/templates/build-ansible-bundle.sh.tftpl")
    }),
  ]
}
