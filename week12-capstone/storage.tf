resource "azurerm_storage_account" "fl_storage_account" {
  name     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.fl_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.fl_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "image.zip"
  storage_account_name   = azurerm_storage_account.fl_storage_account.name
  storage_container_name = azurerm_storage_container.storage_container.name
  type                   = "Block"
  source                 = "${path.module}/image.zip"      
}

resource "azurerm_key_vault" "fl_key_vault" {
  name                        = "flwebappkeyvault"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.fl_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

# Access for Terraform user
resource "azurerm_key_vault_access_policy" "terraform_user" {
  key_vault_id = azurerm_key_vault.fl_key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.user_object_id

  secret_permissions = ["Get", "Set", "Delete", "List"]
}

# Access for Web App Managed Identity
resource "azurerm_key_vault_access_policy" "frontend_app" {
  key_vault_id = azurerm_key_vault.fl_key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.frontend.identity[0].principal_id

  secret_permissions = ["Get", "Set", "Delete", "List"]
}

# Store a sample connection string
resource "azurerm_key_vault_secret" "fl_connection_string" {
  name         = "SampleConnectionString"
  value        = "Server=tcp:sqlserver.database.windows.net;Database=mydb;User Id=admin;Password=secret;"
  key_vault_id = azurerm_key_vault.fl_key_vault.id
}

# Store a dummy API key
resource "azurerm_key_vault_secret" "api_key" {
  name         = "DummyApiKey"
  value        = "12345-ABCDE-SECRETKEY"
  key_vault_id = azurerm_key_vault.fl_key_vault.id
}