locals {
  ansible_source_dir  = "${path.module}/../../../src/ansible"
  ansible_env_dir     = "${path.module}/ansible"
  wrapper_script_path = "${path.module}/../../../scripts/run-create-cluster.sh"

  postgres_percona_cluster_vm_name_prefix = "vm-${var.environment}-ppg"
  postgres_percona_ansible_host_name      = "vm-${var.environment}-ansible"
  postgres_percona_lb_name                = "lb-${var.environment}-ppg"
}
