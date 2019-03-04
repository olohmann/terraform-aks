data "azurerm_subscription" "current" {}

locals {
  external_pip_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.external_pip_resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.external_pip_name}"
}

resource "azurerm_public_ip" "firewall_pip" {
  count               = "${var.external_pip_name == "" ? 1 : 0}"
  name                = "${local.prefix_snake}-firewall-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_snake}-${random_id.workspace.hex}"
}

resource "azurerm_firewall" "firewall" {
  name                = "${local.prefix_snake}-firewall"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall_subnet.id}"
    public_ip_address_id= "${var.external_pip_name == "" ? azurerm_public_ip.firewall_pip.id : local.external_pip_id}"
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
      "*.blob.core.windows.net",
      "*.cdn.mscr.io",
      "*.${local.location}.azmk8s.io",
      "*.hcp.${local.location}.azmk8s.io",
      "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}.ods.opinsights.azure.com",
      "${azurerm_log_analytics_workspace.la_monitor_containers.workspace_id}.oms.opinsights.azure.com",
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

    source_addresses = ["${azurerm_virtual_network.vnet.address_space.0}"]

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

resource "local_file" "firewall_config" {
  content = <<EOF
azure_firewall_name = "${azurerm_firewall.firewall.name}"
azure_firewall_resource_group_name = "${azurerm_resource_group.rg.name}"
azure_firewall_pip = "${azurerm_public_ip.firewall_pip.ip_address}"
EOF

  filename = "${path.module}/../04-aks-post-deploy-ingress/${terraform.workspace}_firewall_config.generated.tfvars"
}
