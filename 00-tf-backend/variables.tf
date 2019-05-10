variable "resource_group_name" {
  type = "string"
  description = "Azutr Resource Group Name"
}

variable "storage_account_name" {
  type = "string"
  description = "name of the storage account for the terraform state"
}

variable "storage_container_name" {
  type = "string"
  description = "name of the storage container for the terraform state"
}

variable "storage_account_primary_access_key" {
  type = "string"
  description = "primary access key to access tf state on the SA"
}
