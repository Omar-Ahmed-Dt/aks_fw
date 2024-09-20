terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azurerm_subscription_id
  tenant_id       = var.azurerm_tenant_id
  client_id       = var.azurerm_client_id
  client_secret   = var.azurerm_client_secret

  features {
  }
}
