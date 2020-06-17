resource "kubernetes_secret" "acr_pull_secret_external_cr" {
  // Only deploy the Pull Secret for the EXTERNAL ACR, if pull secret is enabled.
  count = var.use_external_azure_container_registry ? (var.deploy_container_registry_secret ? 1 : 0) : 0

  metadata {
    name = "acr-pull-secret"
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
  // Only deploy the Pull Secret for the INTERNAL ACR, if pull secret is enabled.
  count = var.deploy_azure_container_registry ? (var.deploy_container_registry_secret ? 1 : 0) : 0

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

