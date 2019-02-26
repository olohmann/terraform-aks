resource "kubernetes_cluster_role_binding" "cluster_admins_rb" {
    count = "${length(var.aks_cluster_admins)}"

    metadata {
        name = "cluster-admins-${count.index}"
    }
    role_ref {
        kind = "ClusterRole"
        name = "cluster-admin"
        api_group = "rbac.authorization.k8s.io"
    }
    subject {
        kind = "User"
        name = "${element(var.aks_cluster_admins, count.index)}"
        api_group = "rbac.authorization.k8s.io"
    }
}

resource "kubernetes_service_account" "tiller_sa" {
  metadata {
    name = "tiller-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller_sa_cluster_admin_rb" {
    metadata {
        name = "tiller-cluster-role"
    }
    role_ref {
        kind = "ClusterRole"
        name = "cluster-admin"
        api_group = "rbac.authorization.k8s.io"
    }
    subject {
        kind = "ServiceAccount"
        name = "${kubernetes_service_account.tiller_sa.metadata.0.name}"
        namespace = "kube-system"
        api_group = ""
    }
}

resource "kubernetes_service_account" "ingress_sa" {
  metadata {
    name = "ingress-sa"
    namespace = "${var.ingress_namespace}"
  }
}

resource "kubernetes_cluster_role_binding" "ingress_discovery_rb" {
    metadata {
        name = "app-gw-ingress-cluster-role"
    }
    role_ref {
        kind = "ClusterRole"
        name = "system:discovery"
        api_group = "rbac.authorization.k8s.io"
    }
    subject {
        kind = "ServiceAccount"
        name = "${kubernetes_service_account.ingress_sa.metadata.0.name}"
        namespace = "${var.ingress_namespace}"
        api_group = ""
    }
}


provider "helm" {
    namespace = "${kubernetes_cluster_role_binding.tiller_sa_cluster_admin_rb.subject.0.namespace}"
    service_account = "${kubernetes_cluster_role_binding.tiller_sa_cluster_admin_rb.subject.0.name}"

    service_account = "tiller-sa"
    tiller_image = "gcr.io/kubernetes-helm/tiller:v2.12.3"
    install_tiller = "true"
}

resource "helm_release" "azure_managed_pod_identity_release" {
  name       = "aad-pod-identity-release"
  repository = "../99-externals/aad-pod-identity/charts"
  chart      = "aad-pod-identity"

  # Will be deployed via App GW Chart
  set {
    name  = "azureIdentity.enabled"
    value = "false"
  }
}


resource "helm_repository" "application_gateway_kubernetes_ingress" {
    name = "application-gateway-kubernetes-ingress"
    url  = "https://azure.github.io/application-gateway-kubernetes-ingress/helm/"
}

resource "helm_release" "app_gw_ingress_release" {
  name       = "app-gw-ingress"
  repository = "application-gateway-kubernetes-ingress"
  chart      = "ingress-azure"

  values = [
    "${file("app_gw_ingress_helm_config.generated.yaml")}"
  ]

  set {
    name  = "kubernetes.watchNamespace"
    value = "${var.ingress_namespace}"
  }
}
