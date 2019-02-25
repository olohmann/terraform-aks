resource "azurerm_public_ip" "ingress_app_gw_pip" {
  name                = "${local.prefix_snake}-ingress-app-gw-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  gw_ip_config_name              = "gw_ip_config"
  backend_address_pool_name      = "beap"
  frontend_port_http_name        = "http-feport"
  frontend_port_https_name       = "https-feport"
  frontend_ip_configuration_name = "feip"
  http_setting_name              = "be-htst"
  http_listener_name             = "httplstn"
  request_routing_rule_name      = "rqrt"
}

resource "azurerm_application_gateway" "ingress_app_gw" {
  name                = "${local.prefix_snake}-ingress-app-gw"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${local.gw_ip_config_name}"
    subnet_id = "${azurerm_subnet.gateway_subnet.id}"
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.ingress_app_gw_pip.id}"
  }

  frontend_port {
    name = "${local.frontend_port_http_name}"
    port = 80
  }

  frontend_port {
    name = "${local.frontend_port_https_name}"
    port = 443
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  http_listener {
    name                           = "${local.http_listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_http_name}"
    protocol                       = "Http"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.http_listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }
}