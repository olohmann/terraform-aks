locals {
  prefix_snake = "${lower("${var.prefix}")}"
  ip_rules     = "${length(var.tf_backend_network_access_rules) > 0 ? join(",", var.tf_backend_network_access_rules) : chomp(data.http.myip.body)}"
  hash_suffix  = "${lower(substr(sha256(azurerm_resource_group.rg.id), 0, 6))}"

  resource_group_name    = "${var.tf_backend_resource_group_name != "" ? var.tf_backend_resource_group_name : "${local.prefix_snake}-shared-tf-state-rg"}"
  location               = "${var.tf_backend_location != "" ? var.tf_backend_location : "${var.location}"}"
  storage_account_name   = "${var.tf_backend_storage_account_name != "" ? var.tf_backend_storage_account_name : "${var.prefix}${local.hash_suffix}"}"
  storage_container_name = "${var.tf_backend_storage_container_name != "" ? var.tf_backend_storage_container_name : "tf-state"}"
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_storage_account" "sa" {
  name                      = "${local.storage_account_name}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${azurerm_resource_group.rg.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_blob_encryption    = true
  enable_file_encryption    = true
  enable_https_traffic_only = true

  account_kind = "BlobStorage"
  access_tier  = "Hot"

  network_rules {
    ip_rules = ["${split(",", local.ip_rules)}"]
  }
}

resource "azurerm_storage_container" "sc" {
  name                  = "${local.storage_container_name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.sa.name}"
  container_access_type = "private"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.rg.name}"
}

output "storage_account_name" {
  value = "${azurerm_storage_account.sa.name}"
}

output "container_name" {
  value = "${azurerm_storage_container.sc.name}"
}

output "access_key" {
  value     = "${azurerm_storage_account.sa.primary_access_key}"
  sensitive = true
}

output "backend_config_params" {
  value     = "-backend-config 'resource_group_name=${azurerm_resource_group.rg.name}' -backend-config 'storage_account_name=${azurerm_storage_account.sa.name}' -backend-config 'container_name=${azurerm_storage_container.sc.name}' -backend-config 'access_key=${azurerm_storage_account.sa.primary_access_key}'"
  sensitive = true
}
