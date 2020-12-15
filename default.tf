terraform {
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "~> 2.40.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "tpl-terraform-p-rg"
    storage_account_name  = "terraformstg071"
    container_name        = "terraform-tfstate"
    key                   = "terraform-staticweb.tfstate"
 } 
}

provider "azurerm" {
    features {}
}