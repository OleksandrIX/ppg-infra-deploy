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
}
