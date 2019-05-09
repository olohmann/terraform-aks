resource "random_uuid" "aks_sp_password" {}
resource "random_uuid" "aad_server_app_secret" {}
resource "random_uuid" "aad_client_app_secret" {}


locals {
  aks_sp = "${terraform.workspace}-${var.prefix}-aks-sp"
  aks_sp_password = "${random_uuid.aad_server_app_secret.result}"
  aks_aad_server_sp = "${terraform.workspace}-${var.prefix}-aks-aad-sp"
  aks_aad_server_password = "${random_uuid.aad_server_app_secret.result}"
  aks_aad_client_sp = "${terraform.workspace}-${var.prefix}-aks-aad-sp"
  aks_aad_client_password = "${random_uuid.aad_client_app_secret.result}"
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



resource "azuread_application" "aad_server" {
  name                       = "${local.aks_aad_server_sp}"
  homepage                   = "https://localhost"
  identifier_uris            = ["http://${local.aks_aad_server_sp}"]
  reply_urls                 = ["http://${local.aks_aad_server_sp}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
    resource_access {
      id = "06da0dbc-49e2-44d2-8312-53f166ab848a"
      type = "Scope"
    }
    resource_access {
      id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
}
}

resource "azuread_service_principal" "aks_aad_server_sp" {
  application_id = "${azuread_application.aad_server.application_id}"
}

resource "azuread_service_principal_password" "aks_aad_server_sp_password" {
  service_principal_id = "${azuread_service_principal.aks_aad_server_sp.service_principal_id}"
  value                = "${local.aks_aad_server_password}"
  end_date             = "2022-01-01T00:00:00Z"
}


# client id requires native app and is not usable until this gets released:
# https://github.com/terraform-providers/terraform-provider-azuread/issues/13
# resource "azuread_application" "aad_client" {
#   name                       = "${local.aks_aad_client_sp}"
#   homepage                   = "https://localhost"
#   identifier_uris            = ["http://${aks_aad_client_sp}"]
#   reply_urls                 = ["http://${aks_aad_client_sp}"]
#   available_to_other_tenants = false
#   oauth2_allow_implicit_flow = false
# 
# }
# 
# resource "azuread_service_principal" "aks_aad_client_sp" {
#   application_id = "${azuread_application.aad_server.application_id}"
# }
# 
# resource "azuread_service_principal_password" "aks_aad_client_password" {
#   service_principal_id = "${azuread_service_principal.aks_aad_client_sp.id}"
#   value                = "${local.aks_aad_client_password}"
#   end_date             = "2022-01-01T00:00:00Z"
# }