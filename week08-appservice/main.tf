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
    name      = "VM_week08_ResourceGroup"
    location   = "germanywestcentral"

    tags = {
        Environment = "Terraform create web app"
        Team        = "DevOps"
    }
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "webapp-asp-frauenloop-42"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier, 1 instance
}

# Create the web app
resource "azurerm_linux_web_app" "webapp" {
  name                  = "webapp-frauenloop-42"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.asp.id
  depends_on            = [azurerm_service_plan.asp]
  https_only            = true
  site_config { 
    application_stack {
      python_version = "3.9"
    }
  }
}