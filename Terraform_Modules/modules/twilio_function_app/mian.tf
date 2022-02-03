//Resource Group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}
//App Service Plan
resource "azurerm_app_service_plan" "serviceplan" {
  name                = var.service_plan_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku {
    tier = "Standard"
    size = "S1"
  }
}
//Twillio Integration Storage Account
resource "azurerm_storage_account" "strgacc_twillio" {
  name                     = var.strgacc_name
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
//Twillio Integration Function App
resource "azurerm_function_app" "fnapp_twillio" {
  name                       = var.name
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.serviceplan.id
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
  version                    = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }
}
//Twillio Integration Function App - Dev slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twilliodev" {
  name                       = "dev"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.serviceplan.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
  version                    = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }
}
//Twillio Integration Function App - QA slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twillioqa" {
  name                       = "qa"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.serviceplan.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
  version                    = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }
}
//Twillio Integration Function App - UAT slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twilliouat" {
  name                       = "uat"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.serviceplan.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
  version                    = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  }
}