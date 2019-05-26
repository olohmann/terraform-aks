/* ARM Role Assignments for AKS SP */
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "${azurerm_subnet.aks_subnet.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${var.aks_cluster_sp_object_id}"
  count                = "${var.assign_roles == "true" ? 1 : 0}"
}

/* Data Role Assignment for AKS SP */
resource "azurerm_role_assignment" "acr_pull" {
  count                = "${var.azure_container_registry_id != "" ? (var.assign_roles == "true" ? 1 : 0) : 0}"
  scope                = "${var.azure_container_registry_id}"
  role_definition_name = "AcrPull"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}

resource "azurerm_role_assignment" "acr_dedicated_pull" {
  count                = "${var.create_azure_container_registry == "true" ? (var.assign_roles == "true" ? 1 : 0) : 0}"
  scope                = "${azurerm_container_registry.acr.id}"
  role_definition_name = "AcrPull"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}
