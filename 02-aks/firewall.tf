data "azurerm_subscription" "current" {}

locals {
  external_pip_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.external_pip_resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.external_pip_name}"
  generated_pip_id = "${data.azurerm_subscription.current.id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/publicIPAddresses/${terraform.workspace}-${var.prefix}-firewall-pip"
}

resource "azurerm_public_ip" "firewall_pip" {
  count               = "${var.external_pip_name == "" ? 1 : 0}"
  name                = "${local.prefix_snake}-firewall-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_snake}-${local.hash_suffix}"
}

resource "azurerm_firewall" "firewall" {
  name                = "${local.prefix_snake}-firewall"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall_subnet.id}"
    public_ip_address_id = "${var.external_pip_name == "" ? local.generated_pip_id : local.external_pip_id}"
  }
}

resource "azurerm_firewall_application_rule_collection" "egress_rules_fqdn" {
  name                = "${local.prefix_snake}-aks-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  priority            = 100
  action              = "Allow"

  rule {
    name = "aks-rules-https"

    source_addresses = ["${azurerm_virtual_network.vnet.address_space.0}"]

    target_fqdns = [
      "*.hcp.${local.location}.azmk8s.io",
      "*.tun.${local.location}.azmk8s.io",

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
      "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}.ods.opinsights.azure.com",
      "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}.oms.opinsights.azure.com",
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

    source_addresses = ["${azurerm_virtual_network.vnet.address_space.0}"]

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
  name                = "aks-rules-cluster-egress"
  azure_firewall_name = "${azurerm_firewall.firewall.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
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
