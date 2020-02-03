terraform {
  backend "azurerm" {
    key = "aks_post_deploy.tfstate"
  }
}
