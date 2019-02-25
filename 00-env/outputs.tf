output "aks_cluster_sp_app_id" {
  value = "${azuread_application.aks_app.application_id}"
}

output "aks_cluster_sp_object_id" {
  value = "${azuread_service_principal.aks_app_sp.id}"
}

output "aks_cluster_sp_secret" {
  value = "${local.aks_sp_password}"
}

output "aks_aad_integration_message" {
  value = "Follow https://docs.microsoft.com/en-us/azure/aks/aad-integration for getting an AAD enabled AKS cluster."
}

