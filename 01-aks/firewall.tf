resource "azurerm_public_ip" "egress_firewall_pip" {
  name                = "${local.prefix_snake}-egress-firewall-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "egress_firewall" {
  name                = "${local.prefix_snake}-egress-firewall"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall_subnet.id}"
    public_ip_address_id = "${azurerm_public_ip.egress_firewall_pip.id}"
  }
}

resource "azurerm_firewall_application_rule_collection" "egress_rules_fqdn" {
  name                = "${local.prefix_snake}-aks-egress"
  azure_firewall_name = "${azurerm_firewall.egress_firewall.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  priority            = 100
  action              = "Allow"

  rule {
    name = "aks-rules"

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
      "storage.googleapis.com"
    ]

    protocol {
      port = 443
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "egress_rules_ssh" {
  name                = "aks-rules-ssh"
  azure_firewall_name = "${azurerm_firewall.egress_firewall.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  priority            = 150
  action              = "Allow"

  rule {
    name = "aks-rules-ssh"

    source_addresses = ["${azurerm_virtual_network.vnet.address_space.0}"]

    destination_ports = [
      "22",
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "TCP"
    ]
  }
}