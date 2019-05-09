locals {
  prefix_snake = "${terraform.workspace}-${var.prefix}"
  prefix_flat = "${terraform.workspace}${var.prefix}"
  location = "${lower(replace(var.location, " ", ""))}"

  # vnet           10.0.0.0/16 -> IP Range: 10.0.0.1 - 10.0.255.254
  # aks            10.0.0.0/20 -> IP Range: 10.0.0.1 - 10.0.15.254
  # aks services   10.1.0.0/20 -> IP Range: 10.1.0.1 - 10.1.15.254
  # docker bridge  172.17.0.1/16
  # firewall       10.0.240.0/24 -> IP Range: 10.0.240.1 - 10.0.240.254
  # app gw         10.0.242.0/24 -> IP Range: 10.0.242.1 - 10.0.242.254
  vnet_cidr              = "10.0.0.0/16"
  aks_subnet_cidr        = "10.0.0.0/20"
  aks_service_cidr       = "10.1.0.0/20"
  aks_dns_service_ip     = "10.1.0.10"
  docker_bridge_cidr     = "172.17.0.1/16"
  firewall_subnet_cidr   = "10.0.240.0/24"
}

resource "random_id" "workspace" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = "${azurerm_resource_group.rg.name}"
  }

  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_snake}-aks-rg"
  location = "${var.location}"
}
