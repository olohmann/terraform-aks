provider "azurerm" {
    version = "~>1.25.0"
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

provider "kubernetes" {
    version = "~>1.5.1"
}

provider "helm" {
    version = "~>0.8.0"
    namespace = "kube-system"
    service_account = "tiller-sa"
    tiller_image = "gcr.io/kubernetes-helm/tiller:v2.12.3"
    install_tiller = "true"
}