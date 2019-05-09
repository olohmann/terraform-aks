/* Role Assignments for AKS SP */
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "${azurerm_subnet.aks_subnet.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.aks_app_sp.id}"
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = "${var.azure_container_registry_id != "" ? 1 : 0}"
  scope                = "${var.azure_container_registry_id}"
  role_definition_name = "AcrPull"
  principal_id         = "${azuread_service_principal.aks_app_sp.id}"
}
