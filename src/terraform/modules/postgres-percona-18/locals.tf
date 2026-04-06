locals {
  vm_data_disks = {
    for pair in flatten([
      for vm_i in range(var.cluster_vm.count) : [
        for disk_cfg in var.data_disks : {
          key        = "${vm_i}-lun-${disk_cfg.lun}"
          vm_index   = vm_i
          disk_lun   = disk_cfg.lun
          config     = disk_cfg
        }
      ]
    ]) : pair.key => pair
  }

  lb_rules = {
    for rule_name, rule in var.lb.rules :
    rule_name => {
      frontend_port           = rule.frontend_port
      backend_port            = coalesce(rule.backend_port, rule.frontend_port)
      protocol                = coalesce(rule.protocol, var.lb.default_protocol)
      probe_port              = coalesce(rule.probe_port, coalesce(rule.backend_port, rule.frontend_port))
      probe_protocol          = coalesce(rule.probe_protocol, var.lb.default_protocol)
      probe_request_path      = rule.probe_request_path
      idle_timeout_in_minutes = coalesce(rule.idle_timeout_in_minutes, var.lb.default_idle_timeout_minutes)
      disable_outbound_snat   = coalesce(rule.disable_outbound_snat, var.lb.default_disable_outbound_snat)
    }
  }

  nic_backend_association = {
    for pair in setproduct(range(var.cluster_vm.count), keys(local.lb_rules)) :
    "${pair[0]}-${pair[1]}" => {
      nic_index = pair[0]
      rule_name = tostring(pair[1])
    }
  }

  ansible_host_cloud_init = templatefile("${path.module}/templates/ansible-host-cloud-init.sh.tftpl", {
    admin_username = var.admin_username
  })

  vm_details_map = {
    for i in range(var.cluster_vm.count) :
    azurerm_linux_virtual_machine.vm[i].name => {
      private_ip = azurerm_network_interface.nic[i].private_ip_address
    }
  }

  db_node_private_ips = [for vm_name in sort(keys(local.vm_details_map)) : local.vm_details_map[vm_name].private_ip]

  generated_inventory_content = yamlencode({
    db_cluster = {
      children = {
        pg_nodes = {
          hosts = {
            for vm_name, vm in local.vm_details_map :
            vm_name => {
              ansible_host = vm.private_ip
            }
          }
        }
      }
    }
  })

  ansible_secret_vars = {
    # psql_superuser_password   = random_password.psql_superuser_password.result
    # psql_replication_password = random_password.psql_replication_password.result
    # pgbouncer_auth_password   = random_password.pgbouncer_auth_password.result
    # patroni_restapi_password  = random_password.patroni_restapi_password.result
    # pgbackrest_cipher_pass    = random_password.pgbackrest_cipher_pass.result
    pgbackrest_azure_key      = var.pgbackrest_azure_key
  }

  ansible_secret_vars_json = jsonencode(local.ansible_secret_vars)

  ansible_env_files = var.ansible_env_dir == "" ? [] : try(fileset(var.ansible_env_dir, "**"), [])
}
