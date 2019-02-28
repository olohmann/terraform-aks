resource "azurerm_container_registry" "acr" {
  count                    = "${var.create_azure_container_registry == "true" ? 1 : 0}"
  name                     = "${local.prefix_flat}${random_id.workspace.hex}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  sku                      = "Standard"
  admin_enabled            = false
}

resource "azurerm_role_assignment" "acr_dedicated_pull" {
  count                = "${var.create_azure_container_registry == "true" ? 1 : 0}"
  scope                = "${azurerm_container_registry.acr.id}"
  role_definition_name = "acrpull"
  principal_id         = "${var.aks_cluster_sp_object_id}"
}
