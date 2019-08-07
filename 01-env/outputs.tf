output "aks_aad_integration_message" {
  value = "If not already done, follow https://docs.microsoft.com/en-us/azure/aks/aad-integration for getting an AAD enabled AKS cluster."
}

output "aks_cluster_sp_app_id" {
  value = "${var.create_aks_cluster_sp == "false" ? "" : azuread_application.aks_app.*.application_id[0]}"
}

output "aks_cluster_sp_object_id" {
  value = "${var.create_aks_cluster_sp == "false" ? "" : azuread_service_principal.aks_app_sp.*.id[0]}"
}

output "aks_cluster_sp_secret" {
  value     = "${var.create_aks_cluster_sp == "false" ? "" : random_uuid.aks_sp_password.*.result[0]}"
  sensitive = true
}
