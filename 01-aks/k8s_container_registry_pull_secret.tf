resource "kubernetes_secret" "acr_external_pull_secret" {
  count = var.deploy_container_registry_secret ? (var.use_external_azure_container_registry ? 1 : 0) : 0

  metadata {
    name = "acr-external-pull-secret"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "https://${data.azurerm_container_registry.acr_external[0].name}.azurecr.io" : {
          email    = "ignore@localhost"
          username = data.azurerm_container_registry.acr_external[0].admin_username
          password = data.azurerm_container_registry.acr_external[0].admin_password
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "acr_pull_secret" {
  count = var.deploy_container_registry_secret ? 1 : 0

  metadata {
    name = "acr-pull-secret"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "https://${azurerm_container_registry.acr[0].name}.azurecr.io" : {
          email    = "ignore@localhost"
          username = azurerm_container_registry.acr[0].admin_username
          password = azurerm_container_registry.acr[0].admin_password
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

