terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-ppg-cluster-dev"
    storage_account_name = "ppgclusterpgbackrest2"
    container_name       = "tfstate"
    key                  = "test-azure/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
