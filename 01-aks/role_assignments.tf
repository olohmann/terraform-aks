/* ARM Role Assignments for AKS SP */
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.assign_roles ? 1 : 0
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = local.aks_sp_object_id
}

/* Required to support an external ELB with a static IP as an alternative to the Azure Firewall */
resource "azurerm_role_assignment" "network_contributor_resource_group" {
  count                = var.assign_roles == true ? 1 : 0
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = local.aks_sp_object_id
}

/* Faster Monitoring Results, see https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-update-metrics */
resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
  count                = var.assign_roles == true ? 1 : 0
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = local.aks_sp_object_id
}

/* Data Role Assignment for AKS SP */
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.external_azure_container_registry_id != "" ? (var.assign_roles ? 1 : 0) : 0
  scope                = var.external_azure_container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = local.aks_sp_object_id
}

resource "azurerm_role_assignment" "acr_dedicated_pull" {
  count                = var.create_azure_container_registry ? (var.assign_roles ? 1 : 0) : 0
  scope                = azurerm_container_registry.acr.*.id[count.index]
  role_definition_name = "AcrPull"
  principal_id         = local.aks_sp_object_id
}
