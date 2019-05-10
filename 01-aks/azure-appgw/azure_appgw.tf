# # Locals block for hardcoded names. 
locals {
    backend_address_pool_name      = "${var.prefix_snake}-beap"
    frontend_port_name             = "${var.prefix_snake}-feport"
    frontend_ip_configuration_name = "${var.prefix_snake}-feip"
    http_setting_name              = "${var.prefix_snake}-be-htst"
    listener_name                  = "${var.prefix_snake}-httplstn"
    request_routing_rule_name      = "${var.prefix_snake}-rqrt"
    redirect_configuration_name    = "${var.prefix_snake}-rdrcfg"
    app_gateway_subnet_name = "appgwsubnet"
}

 resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.prefix_snake}-appgw-pip"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix_snake}-${var.workspace_random_id}" 
}

# Subnet Calc: 10.0.10.0/24 -> IP Range: 10.0.10.1 - 10.0.10.254
resource "azurerm_subnet" "appgw_subnet_fe" {
  name                 = "${var.prefix_snake}-appgw-fe"
  resource_group_name  = "${var.resource_group}"
  address_prefix       = "${var.appgw_subnet_cidr}"
  virtual_network_name = "${var.vnet_name}"

}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix_snake}-appgateway"
  resource_group_name = "${var.resource_group}"
  location            = "${var.resource_group_location}"

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "${var.prefix_snake}-ip-config"
    subnet_id = "${azurerm_subnet.appgw_subnet_fe.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.appgw_pip.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    path         = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                        = "${local.request_routing_rule_name}"
    rule_type                   = "Basic"
    http_listener_name          = "${local.listener_name}"
    backend_address_pool_name   = "${local.backend_address_pool_name}"
    backend_http_settings_name  = "${local.http_setting_name}"
  }
}
