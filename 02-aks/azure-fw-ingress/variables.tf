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


variable "vnet_cidr" {
  type = "string"
  description = "The VNET CIDR of the AKS Cluster"
}

variable "vnet_address_space" {
  type = "list"
}


variable "firewall_subnet_cidr" {
    type = "string"
    description = "Set CIDR Range for the Azure Firewall Subnet"
    default = "10.0.240.0/24"

}

variable "resource_group" {
  type = "string"
  description = "Resource Group of the AKS Cluster"  
}

variable "resource_group_location" {
  type = "string"
  description = "Resource Group Location of the AKS Cluster"  
}

variable "la_monitor_containers_workspace_id" {
  
}


variable "workspace_random_id" {
  type = "string"
  description = "the Random ID of the Terraform AKS Deployment"
  
}
