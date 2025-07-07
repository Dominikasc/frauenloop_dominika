terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.0.2"
        }
    }

    required_version = ">= 1.1.0"
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name        = "frauenloop-week06"
    location    = "germanywestcentral"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                 = "week05-vnet"
    address_space        =["20.0.0.0/16"]   
    location             = "germanywestcentral"
    resource_group_name  = azurerm_resource_group.rg.name
}

# Create subnet 1
resource "azurerm_subnet" "subnet-1" {
    name                 = "week05-subnet1"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["20.0.1.0/24"]
}

# Create subnet 2
resource "azurerm_subnet" "subnet-2" {
    name                 = "week05-subnet2"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["20.0.2.0/24"]
}
