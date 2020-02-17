resource "kubernetes_secret" "acr_external_pull_secret" {
  count = var.deploy_container_registry_secret ? (var.use_external_azure_container_registry ? 1 : 0) : 0

  metadata {
    name = "acr_external_pull_secret"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "https://${data.azurerm_container_registry.acr_external.name}.azurecr.io" : {
          email    = "ignore@localhost"
          username = data.azurerm_container_registry.acr_external.admin_username
          password = base64decode(data.azurerm_container_registry.acr_external.admin_password)
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "acr_pull_secret" {
  count = var.deploy_container_registry_secret ? 1 : 0

  metadata {
    name = "acr_pull_secret"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "https://${azurerm_container_registry.acr.name}.azurecr.io" : {
          email    = "ignore@localhost"
          username = azurerm_container_registry.acr.admin_username
          password = base64decode(azurerm_container_registry.acr.admin_password)
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

