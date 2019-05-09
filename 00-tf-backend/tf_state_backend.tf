resource "local_file" "backend_config_aks" {
  content = <<EOF
resource_group_name  = "${var.resource_group_name}"
storage_account_name = "${var.storage_account_name}"
container_name       = "${var.storage_container_name}"
access_key           = "${var.storage_account_primary_access_key}"
key                  = "aks.tfstate"
EOF

  filename = "${path.module}/../01-aks/backend.tfvars"
}
