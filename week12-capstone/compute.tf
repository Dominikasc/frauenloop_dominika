# Create the Linux App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier, 1 instance
}

# Create the web app
resource "azurerm_linux_web_app" "frontend" {
  name                = var.web_app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      node_version = "12-lts"
    }
  }

  app_settings = {
    "WEBSITES_PORT" = "3000"
  }
}

# App Service Monitoring

resource "azurerm_log_analytics_workspace" "main" {
  name                = "webappanalytics"
  location            = var.location
  resource_group_name = azurerm_resource_group.fl_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "fl_appservice_diagnostics" {
  name               = "fl_appservice-diagnostic"
  target_resource_id = azurerm_key_vault.fl_key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
  
  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

# Storage account monitoring

resource "azurerm_monitor_diagnostic_setting" "fl_storage_diag" {
  name                       = "fl_storage-diagnostic"
  target_resource_id         = azurerm_storage_account.fl_storage_account.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
