resource "kubernetes_cluster_role_binding" "cluster_admins_rb" {
  count = length(var.aks_cluster_admins)

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
    name = element(var.aks_cluster_admins, count.index)
    api_group = "rbac.authorization.k8s.io"
  }
}
