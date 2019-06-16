variable "deploy_azure_firewall" {
  type = "string"
  description = "If 'true' (should be the case for QA & PROD deployments) an Azure Firewall is put in front of the cluster to monitor in- and egress traffic. If 'false', an Azure External LB will be deployed w/o any filtering what so ever."
  default = "true"
}

variable "prefix_snake" {
  type = "string"
}

variable "hash_suffix" {
  type = "string"
}

variable "resource_group_name" {
  type = "string"
}

variable "resource_group_location" {
  type = "string"
}

variable "vnet_name" {
  type = "string"
}

variable "vnet_address_space" {
  type = "string"
  description = "azurerm_virtual_network.vnet.address_space.0"
}

variable "firewall_subnet_cidr" {
  type = "string"
}

variable "external_pip_name" {
  type        = "string"
  description = "If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one."
}

variable "external_pip_resource_group" {
  type        = "string"
  description = "If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one."
}

variable "log_analytics_workspace_id" {
  type = "string"
}

variable "log_analytics_id" {
  type = "string"
}
