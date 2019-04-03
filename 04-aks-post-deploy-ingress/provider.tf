provider "kubernetes" {
    version = ">=1.5.1"
}

provider "helm" {
    version = ">=0.8.0"
    namespace = "kube-system"
    service_account = "tiller-sa"
<<<<<<< HEAD
    tiller_image = "gcr.io/kubernetes-helm/tiller:v2.12.3"
=======
>>>>>>> 3f2359b612b977443cf2f5914ff29bed2790831c
    install_tiller = "true"
}