locals {
  // Little TF "hack" - use a map to signal either an empty or a one-set entry.
  // Easier to read than doing count-based deployments.
  fw_deployment_map = var.deploy_egress_lockdown ? {} : { fw = true }
}

resource "azurerm_subnet" "firewall_subnet" {
  for_each             = local.fw_deployment_map
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefix       = local.firewall_subnet_cidr
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "firewall_pip" {
  for_each = local.fw_deployment_map

  name                = "${local.prefix_kebap}-${local.hash_suffix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_kebap}-${local.hash_suffix}"
}

resource "azurerm_route_table" "aks_subnet_firewall_rt" {
  for_each = local.fw_deployment_map

  name                = "${local.prefix_kebap}-${local.hash_suffix}-rt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[each.key].ip_configuration[0].0.private_ip_address
  }
}

resource "azurerm_firewall" "firewall" {
  for_each = local.fw_deployment_map

  name                = "${local.prefix_kebap}-${local.hash_suffix}-fw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet[each.key].id
    public_ip_address_id = azurerm_public_ip.firewall_pip[each.key].id
  }
}

// Config: https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/master/articles/aks/limit-egress-traffic.md
resource "azurerm_firewall_application_rule_collection" "egress_rules_fqdn" {
  for_each = local.fw_deployment_map

  name                = "${local.prefix_kebap}-${local.hash_suffix}-aks-egress"
  azure_firewall_name = azurerm_firewall.firewall[each.key].name
  resource_group_name = azurerm_firewall.firewall[each.key].resource_group_name
  priority            = 100
  action              = "Allow"

  /*
  | *.hcp.\<location\>.azmk8s.io | HTTPS:443, TCP:22, TCP:9000 | This address is the API server endpoint. Replace *\<location\>* with the region where your AKS cluster is deployed. |
  | *.tun.\<location\>.azmk8s.io | HTTPS:443, TCP:22, TCP:9000 | This address is the API server endpoint. Replace *\<location\>* with the region where your AKS cluster is deployed. |
  | aksrepos.azurecr.io          | HTTPS:443 | This address is required to access images in Azure Container Registry (ACR). This registry contains third-party images/charts (for example, metrics server, core dns, etc.) required for the functioning of the cluster during upgrade and scale of the cluster|
  | *.blob.core.windows.net      | HTTPS:443 | This address is the backend store for images stored in ACR. |
  | mcr.microsoft.com            | HTTPS:443 | This address is required to access images in Microsoft Container Registry (MCR). This registry contains first-party images/charts(for example, moby, etc.) required for the functioning of the cluster during upgrade and scale of the cluster |
  | *.cdn.mscr.io                | HTTPS:443 | This address is required for MCR storage backed by the Azure content delivery network (CDN). |
  | management.azure.com         | HTTPS:443 | This address is required for Kubernetes GET/PUT operations. |
  | login.microsoftonline.com    | HTTPS:443 | This address is required for Azure Active Directory authentication. |
  | ntp.ubuntu.com               | UDP:123   | This address is required for NTP time synchronization on Linux nodes. |
  | packages.microsoft.com       | HTTPS:443 | This address is the Microsoft packages repository used for cached *apt-get* operations.  Example packages include Moby, PowerShell, and Azure CLI. |
  | acs-mirror.azureedge.net 	   | HTTPS:443 | This address is for the repository required to install required binaries like kubenet and Azure CNI. |
  */
  rule {
    name = "aks-rules-https"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "*.hcp.${azurerm_kubernetes_cluster.aks.location}.azmk8s.io",
      "*.tun.${azurerm_kubernetes_cluster.aks.location}.azmk8s.io",

      "aksrepos.azurecr.io",
      "*.blob.core.windows.net",
      "mcr.microsoft.com",
      "*.cdn.mscr.io",
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net",
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  /*
  The following FQDN / application rules are required for AKS clusters that have GPU enabled:

  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | nvidia.github.io | HTTPS:443 | This address is used for correct driver installation and operation on GPU-based nodes. |
  | us.download.nvidia.com | HTTPS:443 | This address is used for correct driver installation and operation on GPU-based nodes. |
  | apt.dockerproject.org | HTTPS:443 | This address is used for correct driver installation and operation on GPU-based nodes. |
  */
  rule {
    name = "aks-rules-gpu-https"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "nvidia.github.io",
      "us.download.nvidia.com",
      "apt.dockerproject.org",
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  /*
  The following FQDN / application rules are required for AKS clusters that have the Azure Monitor for containers enabled:

  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | dc.services.visualstudio.com | HTTPS:443	| This is for correct metrics and monitoring telemetry using Azure Monitor. |
  | *.ods.opinsights.azure.com	| HTTPS:443	| This is used by Azure Monitor for ingesting log analytics data. |
  | *.oms.opinsights.azure.com | HTTPS:443 | This address is used by omsagent, which is used to authenticate the log analytics service. |
  | *.microsoftonline.com | HTTPS:443 | This is used for authenticating and sending metrics to Azure Monitor. |
  | *.monitoring.azure.com | HTTPS:443 | This is used to send metrics data to Azure Monitor. |
  */
  rule {
    name = "aks-rules-monitoring-https"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "dc.services.visualstudio.com",
      "*.ods.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.microsoftonline.com",
      "*.monitoring.azure.com",
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  /*
  The following FQDN / application rules are required for AKS clusters that have the Azure Dev Spaces enabled:
  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | cloudflare.docker.com | HTTPS:443 | This address is used to pull linux alpine and other Azure Dev Spaces images |
  | gcr.io | HTTP:443 | This address is used to pull helm/tiller images |
  | storage.googleapis.com | HTTP:443 | This address is used to pull helm/tiller images |
  | azds-<guid>.<location>.azds.io | HTTPS:443 | To communicate with Azure Dev Spaces backend services for your controller. The exact FQDN can be found in the "dataplaneFqdn" in %USERPROFILE%\.azds\settings.json |
   */
  rule {
    name = "aks-rules-dev-spaces-https"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "cloudflare.docker.com",
      // "gcr.io", // No longer needed with helm3
      "storage.googleapis.com",
      "*.azds.io", // Can be fine-tuned.
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  /*
  The following FQDN / application rules are required for AKS clusters that have the Azure Policy enabled.

  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | gov-prod-policy-data.trafficmanager.net | HTTPS:443 | This address is used for correct operation of Azure Policy. (currently in preview in AKS) |
  | raw.githubusercontent.com | HTTPS:443 | This address is used to pull the built-in policies from GitHub to ensure correct operation of Azure Policy. (currently in preview in AKS) |
  | *.gk.<location>.azmk8s.io | HTTPS:443	| Azure policy add-on that talks to Gatekeeper audit endpoint running in master server to get the audit results. |
  | dc.services.visualstudio.com | HTTPS:443 | Azure policy add-on that sends telemetry data to applications insights endpoint. |
  */
  rule {
    name = "aks-rules-azure-policy-https"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "gov-prod-policy-data.trafficmanager.net",
      "raw.githubusercontent.com",
      "*.gk.${azurerm_kubernetes_cluster.aks.location}.azmk8s.io",
      "dc.services.visualstudio.com"
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  /*
  WINDOWS / Not deployed per default.
  The following FQDN / application rules are required for Windows Server based AKS clusters:

  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | onegetcdn.azureedge.net, winlayers.blob.core.windows.net, winlayers.cdn.mscr.io, go.microsoft.com | HTTPS:443 | To install windows-related binaries |
  | mp.microsoft.com, www<span></span>.msftconnecttest.com, ctldl.windowsupdate.com | HTTP:80 | To install windows-related binaries |
  | kms.core.windows.net | TCP:1688 | To install windows-related binaries |
  */

  /*

  The following FQDN / application rules are recommended for AKS clusters to function correctly:
  | FQDN                                    | Port      | Use      |
  |-----------------------------------------|-----------|----------|
  | security.ubuntu.com, azure.archive.ubuntu.com, changelogs.ubuntu.com | HTTP:80   | This address lets the Linux cluster nodes download the required security patches and updates. |

  */
  rule {
    name = "aks-rules-http"

    source_addresses = [azurerm_virtual_network.vnet.address_space]

    target_fqdns = [
      "security.ubuntu.com",
      "azure.archive.ubuntu.com",
      "changelogs.ubuntu.com"
    ]

    protocol {
      port = 80
      type = "Http"
    }
  }
}

# No FQDN Support for UDP (ntp.ubuntu.com)
resource "azurerm_firewall_network_rule_collection" "egress_rules_network" {
  for_each            = local.fw_deployment_map
  name                = "aks-rules-cluster-egress"
  azure_firewall_name = azurerm_firewall.firewall[each.key].name
  resource_group_name = azurerm_firewall.firewall[each.key].resource_group_name
  priority            = 150
  action              = "Allow"

  rule {
    name = "ntp-ubuntu"

    source_addresses = ["*"]

    destination_ports = [
      "123"
    ]

    destination_addresses = [
      "91.189.89.199",
      "91.189.89.198",
      "91.189.94.4",
      "91.189.91.157"
    ]

    protocols = [
      "UDP"
    ]
  }


  # TODO: Minimize surface via Azure DC list. Will change with tag Support.
  rule {
    name = "aks-rules-tunnel-front"

    source_addresses = ["10.0.0.0/8"]

    destination_ports = [
      "22",
      "9000"
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "TCP"
    ]
  }

  # TODO: Minimize surface via Azure DC list. Will change with tag Support.
  rule {
    name = "aks-rules-internal-tls"

    source_addresses = ["10.0.0.0/8"]

    destination_ports = [
      "443"
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "TCP"
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostics" {
  for_each                   = local.fw_deployment_map
  name                       = "firewall_diagnostics"
  target_resource_id         = azurerm_firewall.firewall[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la_monitor_containers.id

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
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

