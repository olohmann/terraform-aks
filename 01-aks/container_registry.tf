resource "azurerm_container_registry" "acr" {
  count                    = var.create_azure_container_registry ? 1 : 0
  name                     = "${local.prefix_flat}${local.hash_suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  admin_enabled            = var.deploy_container_registry_secret
}

data "azurerm_container_registry" "acr_external" {
  count = var.use_external_azure_container_registry ? 1 : 0
  name = var.external_azure_container_registry_name
  resource_group_name = var.external_azure_container_registry_resource_group_name
}

resource "azurerm_role_assignment" "external_acr_aks_pull" {
  count                = var.use_external_azure_container_registry ? (var.assign_acr_roles ? 1 : 0) : 0
  scope                = data.azurerm_container_registry.acr_external.id
  role_definition_name = "AcrPull"
  principal_id         = local.aks_sp_object_id
}

resource "azurerm_role_assignment" "acr_dedicated_pull" {
  count                = var.create_azure_container_registry ? (var.assign_acr_roles ? 1 : 0) : 0
  scope                = azurerm_container_registry.acr.*.id[count.index]
  role_definition_name = "AcrPull"
  principal_id         = local.aks_sp_object_id
}
