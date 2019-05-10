locals {
  prefix_snake = "${var.prefix}"
}
resource "local_file" "backend_config_aks" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks.tfstate"
EOF

  filename = "${path.module}/../01-aks/backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks_post_deploy.tfstate"
EOF

  filename = "${path.module}/../03-aks-post-deploy/backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy_ingress" {
  content = <<EOF
resource_group_name  = "${azurerm_resource_group.rg.name}"
storage_account_name = "${azurerm_storage_account.sa.name}"
container_name       = "${azurerm_storage_container.sc.name}"
access_key           = "${azurerm_storage_account.sa.primary_access_key}"
key                  = "aks_post_deploy_ingress.tfstate"
EOF

  filename = "${path.module}/../04-aks-post-deploy-ingress/backend.tfvars"
}