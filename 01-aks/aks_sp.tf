locals {
  create_aks_sp_count = var.use_external_aks_cluster_sp ? 0 : 1

  aks_sp = lower("${terraform.workspace}-${var.prefix}-aks-sp")
  aks_aad_sp = lower("${terraform.workspace}-${var.prefix}-aks-aad-sp")

  aks_sp_app_id = var.use_external_aks_cluster_sp ? var.external_aks_cluster_sp_app_id : azuread_application.aks_app.*.application_id[0]
  aks_sp_object_id = var.use_external_aks_cluster_sp ? var.external_aks_cluster_sp_object_id : azuread_service_principal.aks_app_sp.*.id[0]
  aks_sp_secret = var.use_external_aks_cluster_sp ? var.external_aks_cluster_sp_secret : random_string.aks_sp_password.*.result[0]
}

resource "random_string" "aks_sp_password" {
  count   = local.create_aks_sp_count
  length  = 23
  special = false
}

resource "azuread_application" "aks_app" {
  count                      = local.create_aks_sp_count
  name                       = local.aks_sp
  homepage                   = "https://localhost"
  identifier_uris            = ["http://${local.aks_sp}"]
  reply_urls                 = ["http://${local.aks_sp}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "aks_app_sp" {
  count          = local.create_aks_sp_count
  application_id = azuread_application.aks_app.*.application_id[0]
}

resource "azuread_service_principal_password" "aks_app_sp_password" {
  count                = local.create_aks_sp_count
  service_principal_id = azuread_service_principal.aks_app_sp.*.id[0]
  value                = random_string.aks_sp_password.*.result[0]
  end_date             = "2023-01-01T00:00:00Z"
}

