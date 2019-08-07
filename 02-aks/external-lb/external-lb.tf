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

# Route Table: AKS Subnet -> Azure Firewall
resource "azurerm_route_table" "aks_subnet_rt" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-dummy-route"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
}
