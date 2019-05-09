module "azure-fw" {
  source = "./azure-fw"
  resource_group = "${azurerm_resource_group.rg.name}"
  resource_group_location = "${azurerm_resource_group.rg.location}"
  prefix = "${var.prefix}"
  prefix_snake = "${local.prefix_snake}"
  vnet_cidr = "${local.vnet_cidr}"
  vnet_name = "${azurerm_virtual_network.vnet.name}"
  vnet_address_space = ["${azurerm_virtual_network.vnet.address_space.0}"]
  firewall_subnet_cidr = "${local.firewall_subnet_cidr}"
  la_monitor_containers_workspace_id = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"
  workspace_random_id = "${random_id.workspace.hex}"
}

module "azure-fw-ingress" {
  source = "./azure-fw-ingress"
  ingress_namespace = "default"
  azure_firewall_name = "${var.prefix_snake}-firewall"
  resource_group = "${azurerm_resource_group.rg.name}"
  azure_firewall_pip = "${module.azure-fw.azure-firewall-pip}"
  allowed_ingress_source_addresses = "*"
  
}


variable "allowed_ingress_source_addresses" {
  type = "string"
  description = "Allowed source addresses for ingress. Format either '*' for all or a space separated list '1.1.1.1 1.1.1.1/20'"
  default = "*"
}


# OR
# ToDo
