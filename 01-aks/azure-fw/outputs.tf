
output "azure-firewall-pip" {
  value = "${azurerm_public_ip.firewall_pip.0.ip_address}"
}