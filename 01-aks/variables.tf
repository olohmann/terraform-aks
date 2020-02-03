variable "prefix" {
  type        = string
  description = "A prefix used for all resources in this example"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "The Azure region in which all resources in this example should be provisioned."
}

variable "location_log_analytics" {
  type        = string
  default     = "West Europe"
  description = "The Azure region for the Log Analytics Workspace."
}

variable "aks_kubernetes_version" {
  type        = string
  default     = "1.14.8"
  description = "The Kubernetes Version of the AKS cluster."
}

variable "aks_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM Size of node pool."
}

variable "aks_vm_count" {
  type        = string
  default     = "3"
  description = "Number of nodes in node pool."
}

/* Service Principal Configuration */
variable "external_aks_cluster_sp_app_id" {
  type        = string
  description = "The Application ID for the Service Principal to use for this Managed Kubernetes Cluster"
  default     = ""
}

variable "external_aks_cluster_sp_object_id" {
  type        = string
  description = "The Object ID for the Service Principal to use for this Managed Kubernetes Cluster"
  default     = ""
}

variable "external_aks_cluster_sp_secret" {
  type        = string
  description = "The Client Secret for the Service Principal to use for this Managed Kubernetes Cluster"
  default     = ""
}
/* ------------------------------- */

/* --- AAD Configuration --- */
variable "aad_server_app_id" {
  type        = string
  description = "The server app ID for the AAD AKS auth integration."
}

variable "aad_server_app_secret" {
  type        = string
  description = "The server secret for the AAD AKS auth integration."
}

variable "aad_client_app_id" {
  type        = string
  description = "The client app ID for the AAD AKS auth integration."
}

variable "aad_tenant_id" {
  type        = string
  description = "The AAD tenant ID for the AAD AKS auth integration."
}
/* ------------------------------- */

variable "public_ssh_key_path" {
  type        = string
  description = "The Path at which your Public SSH Key is located. Defaults to ~/.ssh/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}

variable "external_azure_container_registry_id" {
  type        = string
  description = "If specified, gives the AKS cluster pull access rights to the provided ACR."
  default     = ""
}

variable "create_azure_container_registry" {
  type        = bool
  description = "Boolean flag, true: create new dedicated ACR, false: don't create dedicated ACR."
  default     = true
}

variable "assign_roles" {
  type        = bool
  description = "If 'true' assigns roles, if 'false' skips the role assignments for the Cluster SP (e.g. Network Contributor Access)."
  default     = true
}

variable "aks_subnet_service_endpoints" {
  type    = list(string)
  default = ["Microsoft.Storage", "Microsoft.KeyVault"]
}
