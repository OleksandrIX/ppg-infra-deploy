terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    ansible = {
      version = "~> 1.4.0"
      source  = "ansible/ansible"
    }
  }
}

provider "azurerm" {
  features {}
}
