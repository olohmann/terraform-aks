module "azure-fw-ingress" {
  source = "./azure-fw-ingress"
  vnet_cidr = "${local.vnet_cidr}"
  vnet_address_space = "${azurerm_virtual_network.vnet.address_space.0}"
  firewall_subnet_cidr = "${local.aks_subnet_cidr}"
  resource_group = "${azurerm_resource_group.rg.name}"
  resource_group_location = "${azurerm_resource_group.rg.location}"
  la_monitor_containers_workspace_id = "azurerm_log_analytics_workspace.la_monitor_containers.workspace_id"
  workspace_random_id = "${random_id.workspace.hex}"
}

# OR
# ToDo