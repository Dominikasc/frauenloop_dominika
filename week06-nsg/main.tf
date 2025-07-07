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
    name                 = "week06-vnet"
    address_space        =["20.0.0.0/16"]   
    location             = "germanywestcentral"
    resource_group_name  = azurerm_resource_group.rg.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
    name                 = "week06-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["20.0.1.0/24"]
}

# Create a network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "week06-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

    security_rule {
        name                        = "allow-ssh"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_ranges      = ["22", "80"]
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
}