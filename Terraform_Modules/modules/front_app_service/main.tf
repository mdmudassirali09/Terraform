//Resource Group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}
//App Service Plan
resource "azurerm_app_service_plan" "serviceplan" {
  name                = var.service_plan_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
}
//Frontend Web App
resource "azurerm_app_service" "frontapp" {
  name                = var.name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "PHP|7.4"
  }
  app_settings = {
  }
}
//Frontend Web App - Dev slot (Deployment Slots)
resource "azurerm_app_service_slot" "frontappdev" {
  name                = "dev"
  app_service_name    = azurerm_app_service.frontapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "PHP|7.4"
  }
  app_settings = {
  }
}
//Frontend Web App - QA slot (Deployment Slots)
resource "azurerm_app_service_slot" "frontappqa" {
  name                = "qa"
  app_service_name    = azurerm_app_service.frontapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "PHP|7.4"
  }
  app_settings = {
  }
}
//Frontend Web App - UAT slot (Deployment Slots)
resource "azurerm_app_service_slot" "frontappuat" {
  name                = "uat"
  app_service_name    = azurerm_app_service.frontapp.name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "PHP|7.4"
  }
  app_settings = {
  }
}