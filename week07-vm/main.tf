terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.0.2"

        }
    }

required_version = "> 1.1.0"
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name      = "VM_week07_ResourceGroup"
    location   = "germanywestcentral"

    tags = {
        Environment = "Terraform create VM"
        Team        = "DevOps"
    }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                 = "week07-vnet"
    address_space        =["20.0.0.0/16"]   
    location             = "germanywestcentral"
    resource_group_name  = azurerm_resource_group.rg.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
    name                 = "week07-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["20.0.1.0/24"]
}

# Create a public ip
resource "azurerm_public_ip" "public_ip" {
  name                = "week07-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# Create a network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "week07-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

    security_rule {
        name                        = "allow-ssh"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                       = "web"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create a network interface
resource "azurerm_network_interface" "nic" {
    name                 = "week07-netinterface"
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    
    ip_configuration {
        name                = "internal"
        subnet_id           = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.public_ip.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sga" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
    name                    = "week07-vm"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = azurerm_resource_group.rg.location
    network_interface_ids   = [azurerm_network_interface.nic.id]
    size                    = "Standard_B1s"
    admin_username          = "azureuser"

    os_disk {
    name        = "myOsDisk"
    caching     = "ReadWrite"
    storage_account_type = "Standard_LRS"
    }
    admin_ssh_key {
    username = "azureuser"
    public_key = file("~/.ssh/week07_key.pub")
    }
    source_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }
}






