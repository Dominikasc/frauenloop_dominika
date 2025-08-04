# Create the Linux App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier, 1 instance
}

# Create the web app
resource "azurerm_linux_web_app" "frontend" {
  name                = var.web_app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
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

resource "azurerm_log_analytics_workspace" "main" {
  name                = "webappanalytics"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

locals {
  web_app_logs = ["AppServiceConsoleLogs",
                  "AppServiceEnvironmentPlatformLogs",
                  "AppServiceAuditLogs",
                  "AppServiceFileAuditLogs",
                  "AppServiceAppLogs",
                  "AppServiceIPSecAuditLogs",
                  "AppServicePlatformLogs"]
}

resource "azurerm_monitor_diagnostic_setting" "appservice_diagnostics" {
  name               = "appservice-diag"
  target_resource_id = azurerm_key_vault.fl_key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
  
  dynamic "log" {
    for_each = local.web_app_logs
    content {
        category = log.value
        enabled  = true

        retention_policy {
        enabled = false
        days    = 0
        }
    }
}
}

resource "azurerm_monitor_action_group" "main" {
  name                = "webapp-storage-actiongroup"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "exampleact"

  webhook_receiver {
    name        = "callmyapi"
    service_uri = "http://webapp.com/alert"
  }
}

resource "azurerm_monitor_metric_alert" "storage_diagnostics" {
  name                = "storage-metricalert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_storage_account.fl_storage_account.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 50

    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}