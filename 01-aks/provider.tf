provider "azurerm" {
    version = "~>1.25.0"
}

provider "azuread" {
    version = "~>0.2.0"
}

provider "local" {
    version = "~>1.1.0"
}

provider "random" {
    version = "~>2.0.0"
}

provider "null" {
    version = "~>2.1.0"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.prefix_snake}-aks"
  resource_group_name = "${local.prefix_snake}-aks-rg"
}

provider "kubernetes" {
  version                = "~>1.5.1"
  load_config_file       = false
  host                   = "${data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  client_certificate     = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
}