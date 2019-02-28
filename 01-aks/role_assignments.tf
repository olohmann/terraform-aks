/* Role Assignments for AKS SP */
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "${azurerm_subnet.aks_subnet.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}

resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = "${azurerm_user_assigned_identity.app_gw_identity.id}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = "${var.azure_container_registry_id != "" ? 1 : 0}"
  scope                = "${var.azure_container_registry_id}"
  role_definition_name = "acrpull"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}

/* Role Assignments for Managed Server Identity */
resource "azurerm_user_assigned_identity" "app_gw_identity" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  name = "${local.prefix_snake}-gw-id"
}

resource "azurerm_role_assignment" "rg_reader" {
  scope                = "${azurerm_resource_group.rg.id}"
  role_definition_name = "Reader"
  principal_id         = "${azurerm_user_assigned_identity.app_gw_identity.principal_id}"
}

resource "azurerm_role_assignment" "network_contributor_app_gw" {
  scope                = "${azurerm_application_gateway.ingress_app_gw.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azurerm_user_assigned_identity.app_gw_identity.principal_id}"
}
