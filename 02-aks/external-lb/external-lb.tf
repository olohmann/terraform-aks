data "azurerm_subscription" "current" {}

locals {
  external_pip_id  = "${data.azurerm_subscription.current.id}/resourceGroups/${var.external_pip_resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.external_pip_name}"
  cnt_deploy       = "${var.deploy_azure_firewall == "false" ? 1 : 0}"
}

resource "azurerm_public_ip" "external_lb_pip" {
  count               = "${var.external_pip_name == "" ? local.cnt_deploy : 0}"
  name                = "${var.prefix_snake}-elb-pip"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = "${var.prefix_snake}-${var.hash_suffix}"
}

// The actual ELB is not created here. We let AKS do it automatically in the MC_ RG.
/*
resource "azurerm_lb" "elb" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-elb"
  resource_group_name = "${var.aks_node_resource_group_name}"
  location            = "${var.resource_group_location}"

  frontend_ip_configuration {
    name                 = "configuration"
    public_ip_address_id = "${var.external_pip_name == "" ? azurerm_public_ip.external_lb_pip.*.id[0]: local.external_pip_id}"
  }
}
*/

# Route Table: AKS Subnet -> Azure Firewall
resource "azurerm_route_table" "aks_subnet_rt" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-dummy-route"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
}
