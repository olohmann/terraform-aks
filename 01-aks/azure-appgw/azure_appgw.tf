# # Locals block for hardcoded names. 
locals {
    backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
    frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
    frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
    http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
    listener_name                  = "${azurerm_virtual_network.test.name}-httplstn"
    request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"
    app_gateway_subnet_name = "appgwsubnet"
}

 resource "azurerm_virtual_network" "test" {
   name                = "${var.virtual_network_name}"
   location            = "${data.azurerm_resource_group.rg.location}"
   resource_group_name = "${data.azurerm_resource_group.rg.name}"
   address_space       = ["${var.virtual_network_address_prefix}"]

   subnet {
     name           = "${var.aks_subnet_name}"
     address_prefix = "${var.aks_subnet_address_prefix}" 
   }

   subnet {
     name           = "appgwsubnet"
     address_prefix = "${var.app_gateway_subnet_address_prefix}"
   }

   tags = "${var.tags}"
 }


 data "azurerm_subnet" "appgwsubnet" {
   name                 = "appgwsubnet"
   virtual_network_name = "${azurerm_virtual_network.test.name}"
   resource_group_name  = "${data.azurerm_resource_group.rg.name}"
 }

 # Public Ip 
 resource "azurerm_public_ip" "test" {
   name                         = "publicIp1"
   location                     = "${data.azurerm_resource_group.rg.location}"
   resource_group_name          = "${data.azurerm_resource_group.rg.name}"
   public_ip_address_allocation = "static"
   sku                          = "Standard"

   tags = "${var.tags}"
 }