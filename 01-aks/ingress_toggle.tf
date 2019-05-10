module "azure-fw" {
  source = "./azure-fw"
  resource_group = "${azurerm_resource_group.rg.name}"
  resource_group_location = "${azurerm_resource_group.rg.location}"
  prefix = "${var.prefix}"
  prefix_snake = "${local.prefix_snake}"
  vnet_name = "${azurerm_virtual_network.vnet.name}"
  vnet_address_space = ["${azurerm_virtual_network.vnet.address_space.0}"]
  firewall_subnet_cidr = "${local.firewall_subnet_cidr}"
  la_monitor_containers_workspace_id = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"
  workspace_random_id = "${random_id.workspace.hex}"
}


# OR
# ToDo
