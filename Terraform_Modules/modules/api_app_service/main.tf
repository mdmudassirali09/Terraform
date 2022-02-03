//Resource Group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}
//App Service Plan
data "azurerm_app_service_plan" "serviceplan" {
  name                = var.service_plan_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
//API Web App
resource "azurerm_app_service" "apiapp" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  app_service_plan_id = data.azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "node|14"
  }
  app_settings = {
  }
}
//API Web App - Dev slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappdev" {
  name                = "dev"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = data.azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "node|14"
  }
  app_settings = {
  }
}
//API Web App - QA slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappqa" {
  name                = "qa"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = data.azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "node|14"
  }
  app_settings = {
  }
}
//API Web App - UAT slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappuat" {
  name                = "uat"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = data.azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "node|14"
  }
  app_settings = {for key, val in var.prodConfig: key => val}
}