variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}

variable "tiller_version" {
  default = "2.13.0"
  description = "Tiller Version (without prefix v)."
}
variable "ingress_namespace" {
  type = "string"
  default = "default"
}

variable "allowed_ingress_source_addresses" {
  type = "string"
  description = "Allowed source addresses for ingress. Format either '*' for all or a space separated list '1.1.1.1 1.1.1.1/20'"
  default = "*"
}

variable "external_pip_name" {
  type = "string"
  description = "If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one."
  default = ""
}

variable "external_pip_resource_group" {
  type = "string"
  description = "If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one."
  default = ""
}

variable "deploy_azure_firewall" {
  type = "string"
  description = "If 'true' (should be the case for QA & PROD deployments) an Azure Firewall is put in front of the cluster to monitor in- and egress traffic. If 'false', an Azure External LB will be deployed w/o any filtering what so ever."
  default = "true"
}
