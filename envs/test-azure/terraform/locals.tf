locals {
  ansible_source_dir  = "${path.module}/../../../src/ansible"
  ansible_env_dir     = "${path.module}/ansible"
  wrapper_script_path = "${path.module}/../../../scripts/run-create-cluster.sh"

  postgres_percona_cluster_vm_name_prefix = "ppg-${var.environment}-cluster"
  postgres_percona_ansible_host_name      = "ppg-${var.environment}-ansible-host"
  postgres_percona_lb_name                = "ppg-${var.environment}-internal-lb"
}
