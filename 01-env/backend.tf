terraform {
  backend "azurerm" {
    key = "env.tfstate"
  }
}
