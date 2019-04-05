provider "kubernetes" {
    version = "~>1.5.1"
}

provider "helm" {
    version = "~>0.8.0"
    namespace = "kube-system"
    service_account = "tiller-sa"
    install_tiller = "true"
}