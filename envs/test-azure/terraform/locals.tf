locals {
  ansible_source_dir = "${path.module}/../../../src/ansible"
  ansible_env_dir    = "${path.module}/../ansible"
  wrapper_script_path = "${path.module}/../../../scripts/run-create-cluster.sh"
}
