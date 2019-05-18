terraform {
  backend "azurerm" {
    key = "aks.tfstate"
  }
}
