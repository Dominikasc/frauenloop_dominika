resource "azurerm_resource_group" "fl_rg" {
    name      = var.resource_group_name
    location   = var.location

    tags = {
        Environment = "Secure Web Application Infrastructure"
        Team        = "DevOps"
    }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                 = var.vnet_name
    address_space        =["10.0.0.0/16"]   
    location             = var.location
    resource_group_name  = azurerm_resource_group.fl_rg.name
}

# Create a frontend subnet
resource "azurerm_subnet" "frontend" {
    name                 = "webapp-frontend-subnet"
    resource_group_name  = azurerm_resource_group.fl_rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Create a backend subnet
resource "azurerm_subnet" "backend" {
    name                 = "webapp-backend-subnet"
    resource_group_name  = azurerm_resource_group.fl_rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "integration" {
  name                 = "appservice-integration-subnet"
  resource_group_name  = azurerm_resource_group.fl_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "appservice-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Enable VNet Integration on the App Service
resource "azurerm_app_service_virtual_network_swift_connection" "frontend_vnet_integration" {
  app_service_id = azurerm_linux_web_app.frontend.id
  subnet_id      = azurerm_subnet.integration.id
}


# Create a public ip
resource "azurerm_public_ip" "frontend_ip" {
  name                = "webapp-public-ip"
  resource_group_name = azurerm_resource_group.fl_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

# NSG allowing SSH or HTTP/HTTPS if needed
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name

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
        name                       = "AllowHTTP"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
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

resource "azurerm_network_interface" "vm_nic" {
  name                = "webapp-netinterface"
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend_nsg_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_linux_virtual_machine" "backend" {
    name                    = var.vm_name
    resource_group_name     = azurerm_resource_group.fl_rg.name
    location                = var.location
    network_interface_ids   = [azurerm_network_interface.vm_nic.id]
    size                    = "Standard_B1s"
    admin_username          = "azureuser"

    identity { 
      type = "SystemAssigned" 
      }
    os_disk {
      name        = "webappOsDisk"
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
    disable_password_authentication = true
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name

  security_rule {
    name                       = "AllowFromAppService"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000" # Or whatever your backend listens on
    source_address_prefix      = "10.0.3.0/24" # Integration subnet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "backend_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}


resource "azurerm_network_security_group" "integration_nsg" {
  name                = "integration-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name

  security_rule {
    name                       = "AllowOutboundToBackend"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    destination_address_prefix = azurerm_subnet.backend.address_prefixes[0]
    source_address_prefix      = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "integration_nsg_assoc" {
  subnet_id                 = azurerm_subnet.integration.id
  network_security_group_id = azurerm_network_security_group.integration_nsg.id
}