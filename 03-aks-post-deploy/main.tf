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