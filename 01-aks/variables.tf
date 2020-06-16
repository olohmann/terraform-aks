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
  description = "Optional. The Azure region for the Log Analytics Workspace. When not specified, the default is to fallback to the 'location' variable."
}

variable "aks_kubernetes_version" {
  type        = string
  default     = "1.16.9"
  description = "The Kubernetes Version of the AKS cluster."
}

variable "aks_default_node_pool" {
  description = "Configuration for the default node pool."
  type = object({
    name                           = string
    node_count                     = number
    vm_size                        = string
    availability_zones             = list(string)
    node_labels                    = map(string)
    node_taints                    = list(string)
    cluster_auto_scaling           = bool
    cluster_auto_scaling_min_count = number
    cluster_auto_scaling_max_count = number
  })

  default = {
    name                           = "default",
    node_count                     = 3,
    vm_size                        = "Standard_DS2_v2"
    availability_zones             = [],
    node_labels                    = {},
    node_taints                    = [],
    cluster_auto_scaling           = false,
    cluster_auto_scaling_min_count = null,
    cluster_auto_scaling_max_count = null
  }
}

variable "aks_additional_node_pools" {
  description = "The map object to configure one or several additional node pools."
  type = map(object({
    node_count                     = number
    vm_size                        = string
    availability_zones             = list(string)
    node_labels                    = map(string)
    node_taints                    = list(string)
    cluster_auto_scaling           = bool
    cluster_auto_scaling_min_count = number
    cluster_auto_scaling_max_count = number
  }))

  default = {}
}

variable "aks_private_cluster_enabled" {
  type        = bool
  default     = false
  description = "Should this Kubernetes Cluster have it's API server only exposed on internal IP addresses?"
}

variable "aks_sku_tier" {
  type        = string
  default     = "Free"
  description = " The SKU Tier that should be used for this Kubernetes Cluster. Changing this forces a new resource to be created. Possible values are Free and Paid."
}

variable "aks_enable_azure_policy_support" {
  type        = bool
  default     = false
  description = "Enable AKS Policy Support."
}

variable "aks_enable_pod_security_policy" {
  type        = bool
  default     = false
  description = "Activate Pod Security Policy: https://docs.microsoft.com/en-us/azure/aks/use-pod-security-policies"
}

variable "aks_subnet_service_endpoints" {
  type    = list(string)
  default = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
}

variable "aks_api_server_authorized_ip_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "The IP ranges to whitelist for incoming traffic to the masters."
}

variable "aks_enable_aad_integration_v1" {
  type        = bool
  default     = false
  description = "Enable the AAD v1 integration. Mutual exclusive with v2."
}

variable "aad_server_app_id" {
  type = string
  default = ""
  description = "Required for AAD integration v1."
}

variable "aad_server_app_secret" {
  type = string
  default = ""
  description = "Required for AAD integration v1."
}

variable "aad_client_app_id" {
  type = string
  default = ""
  description = "Required for AAD integration v1."
}

variable "aad_tenant_id" {
  type = string
  default = ""
  description = "Required for AAD integration v1."
}

variable "aks_enable_aad_integration_v2" {
  type        = bool
  default     = false
  description = "Enable the AAD v2 integration: https://docs.microsoft.com/en-us/azure/aks/managed-aad"
}

variable "aks_admin_group_object_ids" {
  type        = list(string)
  default     = []
  description = "The TBD cluster-admins for the Kubernetes cluster."
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

variable "assign_acr_roles" {
  type        = bool
  description = "If 'true' assigns Pull Rights to AKS, if 'false' skips the role assignments."
  default     = false
}

/* ------ Key Vault -------- */
variable "external_kv_name" {
  type        = string
  description = "The external key vault name. The KV should contain the TLS certificated that is provisioned to the ingress controller and to the Front Door."
}
variable "external_kv_resource_group_name" {
  type        = string
  description = "The external key vault resource group name."
}
variable "external_kv_cert_name" {
  type        = string
  description = "The name of the certificate/secret that points to the TLS certificate (a passwordless PFX, or a CSR merged in Azure KV)."
}

/* --- Front Door and Custom Host Name Binding */
variable "custom_hostname_binding" {
  type        = string
  default     = ""
  description = "Custom Hostname that should be bound by the Front Door."
}

variable "waf_mode" {
  type        = string
  description = "The mode of the WAF of the Frontdoor or App Gateway. Detection as default; Prevention in production mode/stage."
  default     = "Detection"
}
