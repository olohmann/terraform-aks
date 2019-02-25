locals {
  prefix_snake = "${terraform.workspace}-${var.prefix}"
  prefix_flat = "${terraform.workspace}${var.prefix}"
  location = "${lower(replace(var.location, " ", ""))}"

  # vnet           10.0.0.0/16 -> IP Range: 10.0.0.1 - 10.0.255.254
  # aks            10.0.0.0/20 -> IP Range: 10.0.0.1 - 10.0.15.254
  # aks services   10.1.0.0/20 -> IP Range: 10.1.0.1 - 10.0.15.254
  # docker bridge  172.17.0.1/16
  # firewal        10.0.240.0/24 -> IP Range: 10.0.240.1 - 10.0.240.254
  # app gw         10.0.242.0/24 -> IP Range: 10.0.242.1 - 10.0.242.254
  vnet_cidr              = "10.0.0.0/16"
  aks_subnet_cidr        = "10.0.0.0/20"
  aks_service_cidr       = "10.1.0.0/20"
  aks_dns_service_ip     = "10.1.0.10"
  docker_bridge_cidr     = "172.17.0.1/16"
  firewall_subnet_cidr   = "10.0.240.0/24"
  app_gw_subnet_cidr     = "10.0.242.0/24"
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

# Route Table: AKS Subnet -> Azure Firewall
resource "azurerm_route_table" "aks_subnet_rt" {
  name                = "${local.prefix_snake}-default-route"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${azurerm_firewall.egress_firewall.ip_configuration.0.private_ip_address}"
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks_subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${local.aks_subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  route_table_id       = "${azurerm_route_table.aks_subnet_rt.id}"
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = "${azurerm_subnet.aks_subnet.id}"
  route_table_id = "${azurerm_route_table.aks_subnet_rt.id}"
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "gateway_subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${local.app_gw_subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}

# Subnet Calc: 10.0.10.0/24 -> IP Range: 10.0.10.1 - 10.0.10.254
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${local.firewall_subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}
