resource "random_uuid" "aks_sp_password" {}

locals {
  aks_sp = "${lower("${terraform.workspace}-${var.prefix}-aks-sp")}"
  aks_aad_sp = "${lower("${terraform.workspace}-${var.prefix}-aks-aad-sp")}"
  aks_sp_password = "${random_uuid.aks_sp_password.result}"
}

resource "azuread_application" "aks_app" {
  name                       = "${local.aks_sp}"
  homepage                   = "https://localhost"
  identifier_uris            = ["http://${local.aks_sp}"]
  reply_urls                 = ["http://${local.aks_sp}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "aks_app_sp" {
  application_id = "${azuread_application.aks_app.application_id}"
}

resource "azuread_service_principal_password" "aks_app_sp_password" {
  service_principal_id = "${azuread_service_principal.aks_app_sp.id}"
  value                = "${local.aks_sp_password}"
  end_date             = "2022-01-01T00:00:00Z"
}

