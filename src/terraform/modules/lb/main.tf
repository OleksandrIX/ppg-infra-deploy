locals {
  backend_ip_map = {
    for index, ip_address in var.backend_ip_addresses :
    tostring(index) => ip_address
  }

  rules = {
    for rule_name, rule in var.rules :
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

  rule_backend_address_map = {
    for pair in setproduct(keys(local.rules), keys(local.backend_ip_map)) :
    "${pair[0]}-${pair[1]}" => {
      rule_name  = pair[0]
      ip_address = local.backend_ip_map[pair[1]]
      index      = pair[1]
    }
  }
}

resource "azurerm_lb" "ppg_internal_lb" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags

  frontend_ip_configuration {
    name                          = var.frontend_configuration_name
    subnet_id                     = var.frontend_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_private_ip_address
  }
}

resource "azurerm_lb_backend_address_pool" "ppg_backend_pool" {
  for_each = local.rules

  name            = "${var.name}-${each.key}-backend-pool"
  loadbalancer_id = azurerm_lb.ppg_internal_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "ppg_backend_pool_address" {
  for_each = local.rule_backend_address_map

  name                    = "${var.name}-${each.value.rule_name}-backend-${each.value.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ppg_backend_pool[each.value.rule_name].id
  virtual_network_id      = var.backend_vnet_id
  ip_address              = each.value.ip_address
}

resource "azurerm_lb_probe" "ppg_health_probe" {
  for_each = local.rules

  name                = "${var.name}-${each.key}-probe"
  loadbalancer_id     = azurerm_lb.ppg_internal_lb.id
  protocol            = each.value.probe_protocol
  port                = each.value.probe_port
  interval_in_seconds = var.probe_interval_in_seconds
  number_of_probes    = var.number_of_probes
  request_path        = contains(["Http", "Https"], each.value.probe_protocol) ? each.value.probe_request_path : null
}

resource "azurerm_lb_rule" "ppg_lb_rule" {
  for_each = local.rules

  name                           = "${var.name}-${each.key}-rule"
  loadbalancer_id                = azurerm_lb.ppg_internal_lb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = var.frontend_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ppg_backend_pool[each.key].id]
  probe_id                       = azurerm_lb_probe.ppg_health_probe[each.key].id
  disable_outbound_snat          = each.value.disable_outbound_snat
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}
