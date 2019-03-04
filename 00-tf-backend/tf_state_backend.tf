locals {
  prefix_snake = "${terraform.workspace}-${var.prefix}"
}
 
resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix_snake}-tf-admin-rg"
  location = "${var.location}"
}

resource "azurerm_storage_account" "sa" {
  name                      = "${var.prefix}${substr(sha256(azurerm_resource_group.rg.id), 0, 8)}"
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
      ip_rules = ["${var.network_access_rules}"]
  }
}

resource "azurerm_storage_container" "sc" {
  name                  = "tf-state"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.sa.name}"
  container_access_type = "private"
}


resource "local_file" "backend_config_env" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "env.tfstate"
EOF

  filename = "${path.module}/../01-env/${terraform.workspace}_backend.tfvars"
}

resource "local_file" "backend_config_aks" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks.tfstate"
EOF

  filename = "${path.module}/../02-aks/${terraform.workspace}_backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks_post_deploy.tfstate"
EOF

  filename = "${path.module}/../03-aks-post-deploy/${terraform.workspace}_backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy_ingress" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks_post_deploy_ingress.tfstate"
EOF

  filename = "${path.module}/../04-aks-post-deploy-ingress/${terraform.workspace}_backend.tfvars"
}