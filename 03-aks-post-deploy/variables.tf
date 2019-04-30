variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}

# TODO: Alternatively, use a group.
variable "aks_cluster_admins" {
  type = "list"
  description = "The TBD cluster-admins for the Kubernetes cluster."
}
