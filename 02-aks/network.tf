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
  route_table_id       = "${module.azure-fw-ingress.aks-subnet-rt-id}"
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = "${azurerm_subnet.aks_subnet.id}"
  route_table_id = "${azurerm_route_table.aks_subnet_rt.id}"
}
