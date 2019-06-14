provider "azurerm" {
    version = "~>1.30.1"
}

locals {
  prefix_snake = "${terraform.workspace}-${var.prefix}"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.prefix_snake}-aks"
  resource_group_name = "${local.prefix_snake}-aks-rg"
}

provider "kubernetes" {
  version                = "~>1.7.0"
  load_config_file       = false
  host                   = "${data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  client_certificate     = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
}
