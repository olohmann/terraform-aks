output "aks-subnet-rt-id" {
  value = "${azurerm_route_table.aks_subnet_rt.id}"
}

output "azure-firewall-pip" {
  value = "${azurerm_public_ip.firewall_pip.*.ip_address}"
}
