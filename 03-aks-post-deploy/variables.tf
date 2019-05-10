variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}

# TODO: Alternatively, use a group.
variable "aks_cluster_admins" {
  type = "list"
  description = "The TBD cluster-admins for the Kubernetes cluster."
}

variable "tiller_version" {
  default = "2.13.0"
  description = "Tiller Version (without prefix v)."
}
variable "ingress_namespace" {
  type = "string"
  default = "default"
}
