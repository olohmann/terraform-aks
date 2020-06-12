locals {
  prefix_kebab = lower("${var.prefix}-${terraform.workspace}")
  prefix_snake = lower("${var.prefix}_${terraform.workspace}")
  prefix_flat  = lower("${var.prefix}${terraform.workspace}")
  location     = lower(replace(var.location, " ", ""))

  // The idea of this hash value is to use it as a pseudo-random suffix for
  // resources with domain names. It will stay constant over re-deployments
  // per individual resource group. 
  hash_suffix = substr(sha256(azurerm_resource_group.rg.id), 0, 6)

  # vnet           10.0.0.0/16 -> IP Range: 10.0.0.1 - 10.0.255.254
  # aks            10.0.0.0/20 -> IP Range: 10.0.0.1 - 10.0.15.254
  # aks services   10.1.0.0/20 -> IP Range: 10.1.0.1 - 10.0.15.254
  # docker bridge  172.17.0.1/16
  # firewall       10.0.240.0/24 -> IP Range: 10.0.240.1 - 10.0.240.254
  vnet_cidr                = "10.0.0.0/16"
  aks_subnet_cidr          = "10.0.0.0/20"
  aks_service_cidr         = "10.1.0.0/20"
  aks_dns_service_ip       = "10.1.0.10"
  docker_bridge_cidr       = "172.17.0.1/16"
  firewall_subnet_cidr     = "10.0.240.0/26"        // Placeholder Subnet for egress lockdown via AzFW
  app_gw_subnet_cidr       = "10.0.240.64/26"       // Placeholder Subnet for AppGW Ingress
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_snake}_rg"
  location = local.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix_kebab}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["${local.vnet_cidr}"]

}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [local.aks_subnet_cidr]
  virtual_network_name = azurerm_virtual_network.vnet.name
  service_endpoints    = var.aks_subnet_service_endpoints
}
