locals {
  aks_sp     = "${lower("${terraform.workspace}-${var.prefix}-aks-sp")}"
  aks_aad_sp = "${lower("${terraform.workspace}-${var.prefix}-aks-aad-sp")}"
}

resource "random_string" "aks_sp_password" {
  count = "${var.create_aks_cluster_sp == "false" ? 0 : 1}"
  length  = 23
  special = false
}

resource "azuread_application" "aks_app" {
  count                      = "${var.create_aks_cluster_sp == "false" ? 0 : 1}"
  name                       = "${local.aks_sp}"
  homepage                   = "https://localhost"
  identifier_uris            = ["http://${local.aks_sp}"]
  reply_urls                 = ["http://${local.aks_sp}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
}

resource "azuread_service_principal" "aks_app_sp" {
  count          = "${var.create_aks_cluster_sp == "false" ? 0 : 1}"
  application_id = "${azuread_application.aks_app.*.application_id[0]}"
}

resource "azuread_service_principal_password" "aks_app_sp_password" {
  count                = "${var.create_aks_cluster_sp == "false" ? 0 : 1}"
  service_principal_id = "${azuread_service_principal.aks_app_sp.*.id[0]}"
  value                = "${random_string.aks_sp_password.*.result[0]}"
  end_date             = "2022-01-01T00:00:00Z"
}

