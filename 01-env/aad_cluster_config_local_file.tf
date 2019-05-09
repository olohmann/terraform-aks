resource "local_file" "app_cluster_config" {
  content = <<EOF
aks_cluster_sp_app_id = "${azuread_application.aks_app.application_id}"
aks_cluster_sp_object_id = "${azuread_service_principal.aks_app_sp.id}"
aks_cluster_sp_secret = "${local.aks_sp_password}"
EOF

  filename = "${path.module}/../02-aks/${terraform.workspace}_aks_cluster_sp.generated.tfvars"
}

resource "local_file" "aad_server_config" {
  content = <<EOF
aad_server_app_id = "${azuread_application.aad_server_app.id}"
aad_server_app_secret = "${local.aad_server_app_secret}"
EOF

  filename = "${path.module}/../02-aks/${terraform.workspace}_aks_aad_server.generated.tfvars"
}

# resource "local_file" "aad_client_config" {
#   content = <<EOF
# aad_client_app_id = "${azuread_application.aad_client_app_id.id}"
# aad_server_app_secret = "${local.aad_client_secret}"
# EOF
# 
#   filename = "${path.module}/../02-aks/${terraform.workspace}_aks_aad_client.generated.tfvars"
# }
