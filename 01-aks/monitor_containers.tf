resource "azurerm_log_analytics_workspace" "la_monitor_containers" {
  name                = "${local.prefix_kebap}-${local.hash_suffix}"
  location            = var.location_log_analytics
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "la_monitor_containers_sln" {
  solution_name         = "ContainerInsights"
  location              = var.location_log_analytics
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.la_monitor_containers.id
  workspace_name        = azurerm_log_analytics_workspace.la_monitor_containers.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
