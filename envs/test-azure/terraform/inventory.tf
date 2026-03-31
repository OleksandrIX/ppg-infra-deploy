resource "ansible_group" "db_cluster" {
  name     = "db_cluster"
  children = ["pg_nodes"]
}

resource "ansible_group" "pg_nodes" {
  name = "pg_nodes"
}

resource "ansible_host" "pg_node" {
  count = module.database_cluster.vm_count
  name  = "${module.database_cluster.vm_name_prefix}-vm-${count.index}"
  groups = [
    ansible_group.pg_nodes.name
  ]
}
