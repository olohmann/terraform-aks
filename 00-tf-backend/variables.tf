variable "prefix" {
  default = "contoso"
  description = "A prefix used for all resources in this example"
}

variable "location" {
  default     = "West Europe"
  description = "The Azure region in which all resources in this example should be provisioned."
}

# Default, all public IP ranges. Trim as fit.
variable "network_access_rules" {
  type = "list"
  description = "Defines the network level access rules for, e.g. the storage account. Format list of IP addresses and/or IP ranges. If nothing is defined, your current IP address will be added."
  default = []
}
