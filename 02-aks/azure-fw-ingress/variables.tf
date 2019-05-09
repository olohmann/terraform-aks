variable "ingress_namespace" {
  type = "string"
  default = "default"
}

variable "azure_firewall_name" {
  type = "string" 
  description = "Name of the Azure Firewall. Required to configure the DNat settings for the ingress controller."
}
variable "resource_group" {
  type = "string"
  description = "Resource Group of the AKS Cluster"  
}

variable "azure_firewall_pip" {
  type = "string" 
  description = "Public IP Address of the Azure Firewall. Required to configure the DNat settings for the ingress controller."
}

variable "allowed_ingress_source_addresses" {
  type = "string"
  description = "Allowed source addresses for ingress. Format either '*' for all or a space separated list '1.1.1.1 1.1.1.1/20'"
  default = "*"
}
