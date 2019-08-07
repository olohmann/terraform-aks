variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}
variable "location" {
  default     = "West Europe"
  description = "The Azure region in which all resources in this example should be provisioned."
}

variable "create_aks_cluster_sp" {
  default = "true"
  description = "If 'true', service principals for AKS will be generated. In this case you have to provide the Service Principal via variables on your own."
}
