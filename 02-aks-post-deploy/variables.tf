# TODO: Alternatively, use a group.
variable "aks_cluster_admins" {
  type = "list"
  description = "The TBD cluster-admins for the Kubernetes cluster."
}

variable "ingress_namespace" {
  type = "string"
  default = "default"
}
