locals {
  lb_backend_ip_map = {
    for i, nic in azurerm_network_interface.nic :
    tostring(i) => nic.ip_configuration[0].private_ip_address
  }

  lb_rules = {
    for rule_name, rule in var.lb_rules :
    rule_name => {
      frontend_port           = rule.frontend_port
      backend_port            = coalesce(rule.backend_port, rule.frontend_port)
      protocol                = coalesce(rule.protocol, "Tcp")
      probe_port              = coalesce(rule.probe_port, coalesce(rule.backend_port, rule.frontend_port))
      probe_protocol          = coalesce(rule.probe_protocol, "Tcp")
      probe_request_path      = rule.probe_request_path
      idle_timeout_in_minutes = coalesce(rule.idle_timeout_in_minutes, 4)
      disable_outbound_snat   = coalesce(rule.disable_outbound_snat, false)
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
}
