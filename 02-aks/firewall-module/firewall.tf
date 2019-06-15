data "azurerm_subscription" "current" {}

locals {
  external_pip_id  = "${data.azurerm_subscription.current.id}/resourceGroups/${var.external_pip_resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.external_pip_name}"

  cnt_deploy = "${var.deploy_azure_firewall == "true" ? 1 : 0}"
}

# Subnet Calc: 10.0.10.0/24 -> IP Range: 10.0.10.1 - 10.0.10.254
resource "azurerm_subnet" "firewall_subnet" {
  count                = "${local.cnt_deploy}"
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "${var.resource_group_name}"
  address_prefix       = "${var.firewall_subnet_cidr}"
  virtual_network_name = "${var.vnet_name}"
}

# Route Table: AKS Subnet -> Azure Firewall
resource "azurerm_route_table" "aks_subnet_rt" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-default-route"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${azurerm_firewall.firewall.*.ip_configuration[0].0.private_ip_address}"
  }
}

resource "azurerm_public_ip" "firewall_pip" {
  count               = "${var.external_pip_name == "" ? local.cnt_deploy : 0}"
  name                = "${var.prefix_snake}-firewall-pip"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix_snake}-${var.hash_suffix}"
}

resource "azurerm_firewall" "firewall" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-firewall"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.resource_group_location}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall_subnet.*.id[0]}"
    public_ip_address_id = "${var.external_pip_name == "" ? azurerm_public_ip.firewall_pip.*.id[0] : local.external_pip_id}"
  }
}

resource "azurerm_firewall_application_rule_collection" "egress_rules_fqdn" {
  count               = "${local.cnt_deploy}"
  name                = "${var.prefix_snake}-aks-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.*.name[0]}"
  resource_group_name = "${var.resource_group_name}"
  priority            = 100
  action              = "Allow"

  rule {
    name = "aks-rules-https"

    source_addresses = ["${var.vnet_address_space}"]

    target_fqdns = [
      "*.hcp.${var.resource_group_location}.azmk8s.io",
      "*.tun.${var.resource_group_location}.azmk8s.io",

      "aksrepos.azurecr.io",
      "*.blob.core.windows.net",
      "mcr.microsoft.com",
      "*.cdn.mscr.io",
      "management.azure.com",
      "login.microsoftonline.com",
      "api.snapcraft.io",
      "*.docker.io",

      "*.ubuntu.com",
      "packages.microsoft.com",
      "dc.services.visualstudio.com",
      "${var.log_analytics_workspace_id}.ods.opinsights.azure.com",
      "${var.log_analytics_workspace_id}.oms.opinsights.azure.com",
      "*.monitoring.azure.com",

      "gov-prod-policy-data.trafficmanager.net",

      "apt.dockerproject.org",
      "nvidia.github.io",

      // Tiller, remove with 3.0 or re-host
      "gcr.io"
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }

  rule {
    name = "aks-rules-http"

    source_addresses = ["${var.vnet_address_space}"]

    target_fqdns = [
      "api.snapcraft.io",
      "*.ubuntu.com"
    ]

    protocol {
      port = 80
      type = "Http"
    }
  }
}

# TODO: 
resource "azurerm_firewall_network_rule_collection" "egress_rules_network" {
  count               = "${local.cnt_deploy}"
  name                = "aks-rules-cluster-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.*.name[0]}"
  resource_group_name = "${var.resource_group_name}"
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
  count                      = "${local.cnt_deploy}"
  name                       = "firewall_diagnostics"
  target_resource_id         = "${azurerm_firewall.firewall.*.id[0]}"
  log_analytics_workspace_id = "${var.log_analytics_workspace_id}"

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
