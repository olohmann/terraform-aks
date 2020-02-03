resource "azurerm_container_registry" "acr" {
  count                    = var.create_azure_container_registry ? 1 : 0
  name                     = "${local.prefix_flat}${local.hash_suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  admin_enabled            = false
}
