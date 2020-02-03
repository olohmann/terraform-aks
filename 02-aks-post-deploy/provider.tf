provider "azurerm" {
  version = "~>1.42.0"
}

locals {
  prefix_kebap = "${var.prefix}-${terraform.workspace}"
  prefix_snake = "${var.prefix}_${terraform.workspace}"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.prefix_kebap}-aks"
  resource_group_name = "${local.prefix_snake}_rg"
}

provider "kubernetes" {
  version                = "~>1.10.0"
  load_config_file       = false
  host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
}
