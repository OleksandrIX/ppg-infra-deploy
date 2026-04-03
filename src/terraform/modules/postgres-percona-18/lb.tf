resource "azurerm_lb" "lb" {
  name                = var.lb.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.lb.sku

  frontend_ip_configuration {
    name                          = var.lb.frontend_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.lb.private_ip_address_allocation
    private_ip_address            = var.lb.frontend_private_ip_address
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  for_each = local.lb_rules

  name            = "${var.lb.name}-${each.key}-backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_association" {
  for_each = local.nic_backend_association

  network_interface_id    = azurerm_network_interface.nic[each.value.nic_index].id
  ip_configuration_name   = var.cluster_vm.nic_ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool[each.value.rule_name].id
}

resource "azurerm_lb_probe" "health_probe" {
  for_each = local.lb_rules

  name                = "${var.lb.name}-${each.key}-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = each.value.probe_protocol
  port                = each.value.probe_port
  interval_in_seconds = var.lb.probe_interval_in_seconds
  number_of_probes    = var.lb.number_of_probes
  request_path        = contains(["Http", "Https"], each.value.probe_protocol) ? each.value.probe_request_path : null
}

resource "azurerm_lb_rule" "lb_rule" {
  for_each = local.lb_rules

  name                           = "${var.lb.name}-${each.key}-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = var.lb.frontend_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool[each.key].id]
  probe_id                       = azurerm_lb_probe.health_probe[each.key].id
  disable_outbound_snat          = each.value.disable_outbound_snat
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}
