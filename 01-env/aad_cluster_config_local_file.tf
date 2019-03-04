resource "local_file" "aad_cluster_config" {
  content = <<EOF
aks_cluster_sp_app_id = "${azuread_application.aks_app.application_id}"
aks_cluster_sp_object_id = "${azuread_service_principal.aks_app_sp.id}"
aks_cluster_sp_secret = "${local.aks_sp_password}"
EOF

  filename = "${path.module}/../02-aks/${terraform.workspace}_aks_cluster_sp.generated.tfvars"
}
