provider "null" {
  version = "~>2.1.2"
}

provider "azurerm" {
  version = "~>2.6.0"
  features {}
}

provider "local" {
  version = "~>1.4.0"
}

provider "azuread" {
  version = "~>0.7.0"
}

provider "random" {
  version = "~>2.2.1"
}

