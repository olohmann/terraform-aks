locals {
  prefix_snake = "${var.prefix}"
}
 
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"


resource "local_file" "backend_config_env" {
  content = <<EOF
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"
key                  = "env.tfstate"
EOF

  filename = "${path.module}/../01-env/backend.tfvars"
}

resource "local_file" "backend_config_aks" {
  content = <<EOF
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"
key                  = "aks.tfstate"
EOF

  filename = "${path.module}/../02-aks/backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy" {
  content = <<EOF
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"
key                  = "aks_post_deploy.tfstate"
EOF

  filename = "${path.module}/../03-aks-post-deploy/backend.tfvars"
}

resource "local_file" "backend_config_aks_post_deploy_ingress" {
  content = <<EOF
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"
key                  = "aks_post_deploy_ingress.tfstate"
EOF

  filename = "${path.module}/../04-aks-post-deploy-ingress/backend.tfvars"
}
