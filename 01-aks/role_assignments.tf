/* ARM Role Assignments for AKS SP */
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.assign_aks_roles ? 1 : 0
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = local.aks_sp_object_id
}

/* Required to support an external ELB with a static IP as an alternative to the Azure Firewall */
resource "azurerm_role_assignment" "network_contributor_resource_group" {
  count                = var.assign_aks_roles == true ? 1 : 0
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = local.aks_sp_object_id
}

/* Faster Monitoring Results, see https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-update-metrics */
resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
  count                = var.assign_aks_roles == true ? 1 : 0
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = local.aks_sp_object_id
}
