resource "azurerm_public_ip" "appgw_pip" {
  name                = "${local.prefix_snake}-appgw-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_snake}-${random_id.workspace.hex}"
}


# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${local.prefix_snake}-beap"
  frontend_port_name             = "${local.prefix_snake}-feport"
  frontend_ip_configuration_name = "${local.prefix_snake}-feip"
  http_setting_name              = "${local.prefix_snake}-be-htst"
  listener_name                  = "${local.prefix_snake}-httplstn"
  request_routing_rule_name      = "${local.prefix_snake}-rqrt"
}

resource "azurerm_application_gateway" "aks_appgw" {
  name                = "${local.prefix_snake}-appgateway"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${azurerm_subnet.frontend.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
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
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }
}