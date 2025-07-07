terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
      
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "frauenloop-resources"
  location = "germanywestcentral"
}

resource "azurerm_storage_account" "fl_storage_account" {
  name     = "flstorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "fl_storage_container" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.fl_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "fl_blob" {
  name                   = "my-awesome-content.zip"
  storage_account_name   = azurerm_storage_account.fl_storage_account.name
  storage_container_name = azurerm_storage_container.fl_storage_container.name
  type                   = "Block"
  source                 = "some-local-file.zip"
}
