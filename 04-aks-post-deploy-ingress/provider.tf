provider "azurerm" {
  version = "~>1.30.1"
}

provider "local" {
  version = "~>1.2.2"
}

provider "template" {
  version = "~>2.1.0"
}


locals {
  pip_name = "${local.prefix_snake}-${var.deploy_azure_firewall == "true" ? "firewall" : "elb"}-pip"
}


data "azurerm_public_ip" "firewall_data_pip" {
  name                = "${var.external_pip_name == "" ? local.pip_name : "${var.external_pip_name}"}"
  resource_group_name = "${var.external_pip_resource_group == "" ? "${local.firewall_resource_group_name}" : "${var.external_pip_resource_group}"}"
}

locals {
  prefix_snake                 = "${lower("${terraform.workspace}-${var.prefix}")}"
  firewall_resource_group_name = "${local.prefix_snake}-aks-rg"
  firewall_name                = "${local.prefix_snake}-firewall"
  firewall_pip                 = "${data.azurerm_public_ip.firewall_data_pip.ip_address}"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.prefix_snake}-aks"
  resource_group_name = "${local.prefix_snake}-aks-rg"
}

data "external" "helm_init_client_only" {
  program = ["bash", "${path.root}/helm-init.sh"]

  query = {
    env = "${terraform.workspace}"
  }
}

provider "kubernetes" {
  version                = "~>1.7.0"
  load_config_file       = false
  host                   = "${data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  client_certificate     = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
}

provider "helm" {
  version         = "~>0.9.1"
  namespace       = "kube-system"
  service_account = "tiller-sa"
  install_tiller  = "true"
  home            = "${data.external.helm_init_client_only.result.helm_home}"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v${var.tiller_version}"

  kubernetes {
    host                   = "${data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
    client_certificate     = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
    client_key             = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
  }
}

provider "null" {
  version = "~>2.1.0"
}

provider "external" {
  version = "~>1.1.0"
}
