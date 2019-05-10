variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}

variable "location" {
  default     = "West Europe"
  description = "The Azure region in which all resources in this example should be provisioned."
}

variable "location_log_analytics" {
  default = "West Europe"
  description = "The Azure region for the Log Analytics Workspace."
}

variable "aks_kubernetes_version" {
  default = "1.13.5"
  description = "The Kubernetes Version of the AKS cluster."
}

variable "aks_vm_size" {
  default = "Standard_DS2_v2"
  description = "VM Size of node pool."
}

variable "aks_vm_count" {
  default = "3"
  description = "Number of nodes in node pool."
}

variable "aad_client_app_id" {
  description = "The client app ID for the AAD AKS auth integration."
}


variable "aad_tenant_id" {
  description = "The AAD tenant ID for the AAD AKS auth integration."
}

variable "public_ssh_key_path" {
  description = "The Path at which your Public SSH Key is located. Defaults to ~/.ssh/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}

variable "azure_container_registry_id" {
  description = "If specified, gives the AKS cluster pull access rights to the provided ACR."
  default = ""
}

variable "create_azure_container_registry" {
  type         = "string"
  description  = "Boolean flag, true: create new dedicated ACR, false: don't create dedicated ACR."
  default      = "false"
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

variable "aks_cluster_admins" {
  type = "list"
  description = "The TBD cluster-admins for the Kubernetes cluster."
}
