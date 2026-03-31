resource "ansible_group" "db_cluster" {
  name     = "db_cluster"
  children = ["pg_nodes"]
}

resource "ansible_group" "pg_nodes" {
  name = "pg_nodes"
}

resource "ansible_host" "pg_node" {
  count = var.vm_count
  name  = "percona-node-vm-${count.index}"
  groups = [
    ansible_group.pg_nodes.name
  ]
}
