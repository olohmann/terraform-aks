// IMPORTANT
// The AppGW is only deployed, if the flag deploy_appgw_ingress_controller is present.

locals {
  // Little TF "hack" - use a map to signal either an empty or a one-set entry.
  // Easier to read than doing count-based deployments.
  app_gw_deployment_map = var.deploy_appgw_ingress_controller ? { appgw = true } : {}
}

resource "azurerm_subnet" "app_gw_subnet" {
  for_each = local.app_gw_deployment_map
  name                 = "${each.key}_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = local.app_gw_subnet_cidr
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "appgw_pip" {
  for_each = local.app_gw_deployment_map

  name                = "${local.prefix_kebap}-${local.hash_suffix}-appgw-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_kebap}-${local.hash_suffix}-appgw"
}

locals {
  backend_address_pool_name      = "defaultaddresspool"
  frontend_port_http_name        = "feport-http"
  frontend_port_https_name       = "feport-https"
  frontend_ip_configuration_name = "feip"
  backend_http_settings_name     = "be-htst"
  listener_http_name             = "http-lstn"
  listener_https_name            = "https-lstn"
  request_routing_rule_name      = "rqrt"
  redirect_configuration_name    = "rdrcfg"
}

resource "azurerm_application_gateway" "app_gw" {
  for_each = local.app_gw_deployment_map

  // Ignore many aspects of the AppGW configuration as the
  // AppGW will be managed by the Ingress Controller!
  // The only configuration which is actually meaningful here, is the
  // setup of the Public IP association and the configuration of
  // the Azure Firewall.
  lifecycle {
    ignore_changes = [ backend_address_pool, backend_http_settings, http_listener, request_routing_rule, frontend_port, probe ]
  }
  name                = "${local.prefix_kebap}-${local.hash_suffix}-${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gw_subnet[each.key].id
  }

  frontend_port {
    name = local.frontend_port_http_name
    port = 80
  }

  frontend_port {
    name = local.frontend_port_https_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip[each.key].id
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
  }

  backend_http_settings {
    name                                = local.backend_http_settings_name
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_http_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_http_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_http_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }
}

resource "azurerm_monitor_diagnostic_setting" "appgw_waf_access_log" {
  for_each = local.app_gw_deployment_map

  name                       = "appgw_waf_access_log_${each.key}"
  target_resource_id         = azurerm_application_gateway.app_gw[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la_monitor_containers.id

  log {
    category = "ApplicationGatewayFirewallLog"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "ApplicationGatewayAccessLog"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  log {
    category = "ApplicationGatewayPerformanceLog"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
