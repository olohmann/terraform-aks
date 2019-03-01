resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostics" {
  name               = "firewall_diagnostics"
  target_resource_id = "${azurerm_firewall.firewall.id}"
  log_analytics_workspace_id = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true
    retention_policy {
        enabled = false
    }
  }

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true
    retention_policy {
        enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled = false
    
    retention_policy {
      enabled = false
    }
  }
}