output "aks_subnet_rt_id" {
  value = "${var.deploy_azure_firewall == "false" ? azurerm_route_table.aks_subnet_rt.*.id[0] : ""}"
}
