// ---- Overall Deployment Options -----
variable "deploy_egress_lockdown" {
  type        = bool
  default     = false
  description = "If set to 'true' the cluster will be deployed in egress lockdown mode. This setup is mutual EXCLUSIVE with deploying an AppGW ingress controller. That is, an Azure Firewall will be deployed. Details described here: https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic"
}

variable "deploy_appgw_ingress_controller" {
  type        = bool
  default     = false
  description = "If set to 'true' the cluster will be deployed in with an App GW that will be configured as an ingress controller. This setup is mutual EXCLUSIVE with deploying the egress lockdown as this would result in asymmetric traffic."
}

// -----------------------------------

variable "prefix" {
  type        = string
  description = "A prefix used for all resources in this example"
}

variable "location" {
  type        = string
  default     = "northeurope"
  description = "The Azure region in which all resources in this example should be provisioned."
}

variable "log_analytics_location" {
  type        = string
  default     = ""
  description = "The Azure region for the Log Analytics Workspace."
}

variable "aks_kubernetes_version" {
  type        = string
  default     = "1.15.7"
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

variable "aks_node_pool_type" {
  type        = string
  default     = "VirtualMachineScaleSets"
  description = "Type of the Agent Pool. Possible values are AvailabilitySet and VirtualMachineScaleSets. Changing this forces a new resource to be created."
}

variable "aks_enable_azure_policy" {
  type        = bool
  default     = false
  description = "Enable AKS Policy Support."
}

variable "use_pod_security_policy" {
  type        = bool
  default     = false
  description = "Activate Pod Security Policy: https://docs.microsoft.com/en-us/azure/aks/use-pod-security-policies"
}

/* -- Service Principal Configuration -- */
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

/* ----- AKS AAD Configuration --- */
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
/* ----------- SSH --------------- */

variable "public_ssh_key_path" {
  type        = string
  description = "The Path at which your Public SSH Key is located. Defaults to ~/.ssh/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}

/* -------- External ACR --------- */
variable "use_external_azure_container_registry" {
  type        = bool
  description = "Set if use external ACR."
  default     = false
}

variable "external_azure_container_registry_name" {
  type        = string
  description = "Set if use external ACR."
  default     = ""
}

variable "external_azure_container_registry_resource_group_name" {
  type        = string
  description = "Set if use external ACR."
  default     = ""
}

/* ------------ New ACR -------------- */
variable "deploy_azure_container_registry" {
  type        = bool
  description = "Boolean flag, true: create new dedicated ACR, false: don't create dedicated ACR."
  default     = false
}

/* ------ Permission Handling -------- */
variable "deploy_container_registry_secret" {
  type        = bool
  default     = false
  description = "When true, deploys access to the ACR in cluster. See https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes#create-an-image-pull-secret for details."
}

variable "assign_aks_roles" {
  type        = bool
  description = "If 'true' assigns AKS SP roles, if 'false' skips the role assignments for the Cluster SP (e.g. Network Contributor Access)."
  default     = false
}

variable "assign_acr_roles" {
  type        = bool
  description = "If 'true' assigns Pull Rights to AKS, if 'false' skips the role assignments."
  default     = false
}

variable "aks_subnet_service_endpoints" {
  type    = list(string)
  default = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
}

/* ----------- AKS Cluster: Inner Setup ---------- */
variable "aks_cluster_admins" {
  type        = list
  description = "The TBD cluster-admins for the Kubernetes cluster."
}
