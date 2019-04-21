data "azurerm_subscription" "current" {}

locals {
  external_pip_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.external_pip_resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.external_pip_name}"
  generated_pip_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/publicIPAddresses/${terraform.workspace}-${var.prefix}-firewall-pip"
}


resource "azurerm_public_ip" "firewall_pip" {
  count               = "${var.external_pip_name == "" ? 1 : 0}"
  name                = "${var.prefix_snake}-firewall-pip"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix_snake}-${var.workspace_random_id}"
}

# Subnet Calc: 10.0.10.0/24 -> IP Range: 10.0.10.1 - 10.0.10.254
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "${var.resource_group}"
  address_prefix       = "${var.firewall_subnet_cidr}"
  virtual_network_name = "${var.vnet_cidr}"
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.prefix_snake}-firewall"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall_subnet.id}"
    public_ip_address_id = "${var.external_pip_name == "" ? local.generated_pip_id : local.external_pip_id}"
  }
}

resource "azurerm_firewall_application_rule_collection" "egress_rules_fqdn" {
  name                = "${var.prefix_snake}-aks-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.name}"
  resource_group_name = "${var.resource_group}"
  priority            = 100
  action              = "Allow"

  rule {
    name = "aks-rules-https"

    source_addresses = ["${var.vnet_address_space}"]

    target_fqdns = [
      "*.blob.core.windows.net",
      "*.cdn.mscr.io",
      "*.${local.location}.azmk8s.io",
      "*.hcp.${local.location}.azmk8s.io",
      "${var.la_monitor_containers_workspace_id}.ods.opinsights.azure.com",
      "${var.la_monitor_containers_workspace_id}.oms.opinsights.azure.com",
      "api.snapcraft.io",
      "auth.docker.io",
      "azure.archive.ubuntu.com",
      "dc.services.visualstudio.com",
      "download.opensuse.org",
      "gcr.io",
      "k8s.gcr.io",
      "login.microsoftonline.com",
      "management.azure.com",
      "mcr.microsoft.com",
      "packages.microsoft.com",
      "production.cloudflare.docker.com",
      "registry-1.docker.io",
      "security.ubuntu.com",
      "storage.googleapis.com",
      "quay.io",
      "d3uo42mtx6z2cr.cloudfront.net"
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
      "azure.archive.ubuntu.com",
      "download.opensuse.org",
      "security.ubuntu.com"
    ]

    protocol {
      port = 80
      type = "Http"
    }
  }
}

# TODO: 
resource "azurerm_firewall_network_rule_collection" "egress_rules_network" {
  name                = "aks-rules-cluster-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.name}"
  resource_group_name = "${var.resource_group}"
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

  # TODO: Minimize surface via Azure DC list. Will change with VNet Svc Endpoint Support.
  rule {
    name = "aks-rules-ssh"

    source_addresses = ["*"]

    destination_ports = [
      "22",
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

data "azurerm_public_ip" "firewall_data_pip" {
  name                = "${var.external_pip_name == "" ? "${var.prefix_snake}-firewall-pip" : "${var.external_pip_name}"}"
  resource_group_name = "${var.external_pip_resource_group == "" ? "${var.resource_group}" : "${var.external_pip_resource_group}"}"
}

resource "local_file" "firewall_config" {
  content = <<EOF
azure_firewall_name = "${azurerm_firewall.firewall.name}"
azure_firewall_resource_group_name = "${var.resource_group}"
azure_firewall_pip = "${data.azurerm_public_ip.firewall_data_pip.ip_address}"
EOF

  filename = "${path.module}/../04-aks-post-deploy-ingress/${terraform.workspace}_firewall_config.generated.tfvars"
}

# Route Table: AKS Subnet -> Azure Firewall

resource "azurerm_route_table" "aks_subnet_rt" {
  name                = "${var.prefix_snake}-default-route"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group}"

   route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${azurerm_firewall.firewall.ip_configuration.0.private_ip_address}"
  }

}

resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostics" {
  name               = "firewall_diagnostics"
  target_resource_id = "${azurerm_firewall.firewall.id}"
  log_analytics_workspace_id = "${var.la_monitor_containers_workspace_id}"

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