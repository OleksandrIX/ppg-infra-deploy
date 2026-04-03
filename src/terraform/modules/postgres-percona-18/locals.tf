locals {
  lb_backend_ip_map = {
    for i, nic in azurerm_network_interface.nic :
    tostring(i) => nic.ip_configuration[0].private_ip_address
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

  lb_rule_backend_address_map = {
    for pair in setproduct(keys(local.lb_rules), keys(local.lb_backend_ip_map)) :
    "${pair[0]}-${pair[1]}" => {
      rule_name  = pair[0]
      ip_address = local.lb_backend_ip_map[pair[1]]
      index      = pair[1]
    }
  }

  vm_data_disks = {
    for pair in flatten([
      for vm_i in range(var.cluster_vm.count) : [
        for disk_i, disk_cfg in var.data_disks : {
          key        = "${vm_i}-${disk_i}"
          vm_index   = vm_i
          disk_index = disk_i
          config     = disk_cfg
        }
      ]
    ]) : pair.key => pair
  }
}
