locals {
  prefix_snake = "${lower("${terraform.workspace}-${var.prefix}")}"
  prefix_flat  = "${lower("${terraform.workspace}${var.prefix}")}"
  location     = "${lower(replace(var.location, " ", ""))}"

  // The idea of this hash value is to use it as a pseudo-random suffix for
  // resources with domain names. It will stay constant over re-deployments
  // per individual resource group. 
  hash_suffix = "${substr(sha256(azurerm_resource_group.rg.id), 0, 6)}"

  # vnet           10.0.0.0/16 -> IP Range: 10.0.0.1 - 10.0.255.254
  # aks            10.0.0.0/20 -> IP Range: 10.0.0.1 - 10.0.15.254
  # aks services   10.1.0.0/20 -> IP Range: 10.1.0.1 - 10.0.15.254
  # docker bridge  172.17.0.1/16
  # firewall       10.0.240.0/24 -> IP Range: 10.0.240.1 - 10.0.240.254
  vnet_cidr            = "10.0.0.0/16"
  aks_subnet_cidr      = "10.0.0.0/20"
  aks_service_cidr     = "10.1.0.0/20"
  aks_dns_service_ip   = "10.1.0.10"
  docker_bridge_cidr   = "172.17.0.1/16"
  firewall_subnet_cidr = "10.0.240.0/24"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_snake}-aks-rg"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix_snake}-vnet"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["${local.vnet_cidr}"]

}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks_subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${local.aks_subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  route_table_id       = "${var.deploy_azure_firewall == "true" ? module.firewall.aks_subnet_rt_id : module.external_lb.aks_subnet_rt_id}"
  service_endpoints    = "${var.aks_subnet_service_endpoints}"
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = "${azurerm_subnet.aks_subnet.id}"
  route_table_id = "${var.deploy_azure_firewall == "true" ? module.firewall.aks_subnet_rt_id : module.external_lb.aks_subnet_rt_id}"
}


module "firewall" {
  source                      = "./firewall-module"
  deploy_azure_firewall       = "${var.deploy_azure_firewall}"
  prefix_snake                = "${local.prefix_snake}"
  hash_suffix                 = "${local.hash_suffix}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  resource_group_location     = "${local.location}"
  vnet_name                   = "${azurerm_virtual_network.vnet.name}"
  vnet_address_space          = "${azurerm_virtual_network.vnet.address_space.0}"
  firewall_subnet_cidr        = "${local.firewall_subnet_cidr}"
  external_pip_name           = "${var.external_pip_name}"
  external_pip_resource_group = "${var.external_pip_resource_group}"
  log_analytics_id            = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"
  log_analytics_workspace_id  = "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}"
}

module "external_lb" {
  source                      = "./external-lb"
  deploy_azure_firewall       = "${var.deploy_azure_firewall}"
  prefix_snake                = "${local.prefix_snake}"
  hash_suffix                 = "${local.hash_suffix}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  resource_group_location     = "${local.location}"
  external_pip_name           = "${var.external_pip_name}"
  external_pip_resource_group = "${var.external_pip_resource_group}"
  log_analytics_id            = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"
  log_analytics_workspace_id  = "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}"
}
