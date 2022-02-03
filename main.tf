locals {
  name = "${var.client}${var.application}${var.environment}"
}
//Resource Group
resource "azurerm_resource_group" "rg" {
  name     = (var.rg_name == "RG") ? "${local.name}${var.rg_name}" : var.rg_name
  location = var.location
}
//SQL Server
resource "azurerm_mssql_server" "server" {
  name                         = local.name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
}
//SQL Database
resource "azurerm_mssql_database" "db" {
  name        = (var.db_name == "db") ? "${local.name}${var.db_name}" : var.db_name
  server_id   = azurerm_mssql_server.server.id
  create_mode = "Default"
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name    = "S0"
  max_size_gb = 250
}
resource "azurerm_mssql_firewall_rule" "az_ips" {
  name                = "AllowAllWindowsAzureIps"
  server_id           = azurerm_mssql_server.server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
//DNS Zone
data "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = "vpnRG"
}
//SQLSubnet Data
data "azurerm_subnet" "subnet" {
  name                 = "SQLSubnet"
  virtual_network_name = "v-net"
  resource_group_name  = "vpnRG"
}
//Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "endpoint" {
  name                = "${var.client}-privateendpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "${var.client}-privateendpoint"
    private_connection_resource_id = azurerm_mssql_server.server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_zone.id]
  }
}
//App Service Plan
resource "azurerm_app_service_plan" "serviceplan" {
  name                = (var.hosting_plan == "ServicePlan") ? "${local.name}${var.hosting_plan}" : var.hosting_plan
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = var.serviceplan_tier
    size = var.serviceplan_size
  }
}
//Frontend Web App
resource "azurerm_app_service" "frontapp" {
  name                = (var.front_app_service == "") ? local.name : var.front_app_service
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_app_service_plan.serviceplan.location
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
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//Frontend Web App - QA slot (Deployment Slots)
resource "azurerm_app_service_slot" "frontappqa" {
  name                = "qa"
  app_service_name    = azurerm_app_service.frontapp.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//Frontend Web App - UAT slot (Deployment Slots)
resource "azurerm_app_service_slot" "frontappuat" {
  name                = "uat"
  app_service_name    = azurerm_app_service.frontapp.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//Application Insights
resource "azurerm_application_insights" "insights" {
  name                = "${local.name}insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "Node.JS"
}
//API Web App
resource "azurerm_app_service" "apiapp" {
  name                = "${azurerm_app_service.frontapp.name}api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_app_service_plan.serviceplan.location
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
  site_config {
    always_on        = true
    linux_fx_version = "node|14"
  }
  app_settings = {
    "Azure_Blob_Storage_ConnectionString" = "${azurerm_storage_account.strgacc.primary_connection_string}"
    "Azure_Blob_Storage_Container"        = "${azurerm_storage_account.strgacc.primary_blob_endpoint}"
    "CORS_WHITELIST"                      = "['${azurerm_app_service.frontapp.default_site_hostname}','${azurerm_app_service.frontapp.default_site_hostname}','http://localhost:8081', 'http://localhost:8080','*']"
    "EVENT_HUB"                           = "${azurerm_eventhub_authorization_rule.eh_twillio.primary_connection_string}"
    "EVENT_HUB_NAME"                      = "twillio"
    "EVENT_HUB_NAME_SF"                   = "sf"
    "EVENT_HUB_SF"                        = "${azurerm_eventhub_authorization_rule.eh_sf.primary_connection_string}"
    "HTTP_STATUS_CODE_CREATED"            = "201"
    "HTTP_STATUS_CODE_INVALID_DATA"       = "422"
    "HTTP_STATUS_CODE_NOT_FOUND"          = "404"
    "HTTP_STATUS_CODE_SERVER_ERROR"       = "500"
    "HTTP_STATUS_CODE_SUCCESS"            = "200"
    "HTTP_STATUS_CODE_UNAUTHORIZED"       = "403"
    "jwt_expiry"                          = "900s"
    "jwt_refresh_expiry"                  = "24h"
    "port"                                = "8080"
    "prod_port"                           = "8080"
    "NODE_ENV"                            = "production"
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS"  = "7"
    "REDISCACHEHOSTNAME"                  = "${azurerm_redis_cache.redis.hostname}"
    "REDISCACHEKEY"                       = "${azurerm_redis_cache.redis.primary_access_key}"
    "MALICIOUS_FILE_SCAN_URL"             = "${azurerm_app_service.containerapp.default_site_hostname}"
    "SQL_DBNAME"                          = "${azurerm_mssql_database.db.name}"
    "SQL_SERVER"                          = "${azurerm_mssql_server.server.fully_qualified_domain_name}"
    "SQL_USERNAME"                        = var.user_login
    "SQL_PASSWORD"                        = var.user_password
    //Application Insights Configuration
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = "${azurerm_application_insights.insights.instrumentation_key}"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = "${azurerm_application_insights.insights.connection_string}"
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "APPLICATIONINSIGHTS_CONFIGURATION_CONTENT"       = ""
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~3"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "disabled"
    "SnapshotDebugger_EXTENSION_VERSION"              = "disabled"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
  }
}
//API Web App - Dev slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappdev" {
  name                = "dev"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//API Web App - QA slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappqa" {
  name                = "qa"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//API Web App - UAT slot (Deployment Slots)
resource "azurerm_app_service_slot" "apiappuat" {
  name                = "uat"
  app_service_name    = azurerm_app_service.apiapp.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}
//Function Apps Service Plan (Windows)
resource "azurerm_app_service_plan" "serviceplan_windows" {
  name                = "${local.name}windowsplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = var.serviceplan_tier
    size = var.serviceplan_size
  }
}
//Twillio Integration Storage Account
resource "azurerm_storage_account" "strgacc_twillio" {
  name                     = "${local.name}twillio"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.account_tier
  account_replication_type = "GRS"
}
//Twillio Integration Function App
resource "azurerm_function_app" "fnapp_twillio" {
  name                       = "${local.name}-twillio-integration"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.serviceplan_windows.id
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
  version                    = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
    //Application Insights Configuration
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = "${azurerm_application_insights.insights.instrumentation_key}"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = "${azurerm_application_insights.insights.connection_string}"
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "APPLICATIONINSIGHTS_CONFIGURATION_CONTENT"       = ""
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~3"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "disabled"
    "SnapshotDebugger_EXTENSION_VERSION"              = "disabled"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
  }
}
//Twillio Integration Function App - Dev slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twilliodev" {
  name                       = "dev"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.serviceplan_windows.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
}
//Twillio Integration Function App - QA slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twillioqa" {
  name                       = "qa"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.serviceplan_windows.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
}
//Twillio Integration Function App - UAT slot (Deployment Slots)
resource "azurerm_function_app_slot" "fnapp_twilliouat" {
  name                       = "uat"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.serviceplan_windows.id
  function_app_name          = azurerm_function_app.fnapp_twillio.name
  storage_account_name       = azurerm_storage_account.strgacc_twillio.name
  storage_account_access_key = azurerm_storage_account.strgacc_twillio.primary_access_key
}
//assets, vcard, attachments, media Containers - Storage Account 
resource "azurerm_storage_account" "strgacc" {
  name                     = local.name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.account_tier
  account_replication_type = "GRS"
  allow_blob_public_access = true
}
//assets Container
resource "azurerm_storage_container" "ctr_assets" {
  name                  = "assets"
  storage_account_name  = azurerm_storage_account.strgacc.name
  container_access_type = "blob"
}
//, vcard, attachments, media Container
resource "azurerm_storage_container" "ctr_vcard" {
  name                  = "vcard"
  storage_account_name  = azurerm_storage_account.strgacc.name
  container_access_type = "blob"
}
//attachments Container
resource "azurerm_storage_container" "ctr_attachments" {
  name                  = "attachments"
  storage_account_name  = azurerm_storage_account.strgacc.name
  container_access_type = "blob"
}
//media Container
resource "azurerm_storage_container" "ctr_media" {
  name                  = "media"
  storage_account_name  = azurerm_storage_account.strgacc.name
  container_access_type = "blob"
}
//Event Hub Namespace
resource "azurerm_eventhub_namespace" "eventhub" {
  name                = local.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  capacity            = 1
  tags = {
  }
}
//SF Event Hub
resource "azurerm_eventhub" "eh_sf" {
  name                = "sf"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
//SF Event Hub Rules
resource "azurerm_eventhub_authorization_rule" "eh_sf" {
  name                = "SendListenPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eh_sf.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}
//SF_Transaction Event Hub
resource "azurerm_eventhub" "eh_sf_transaction" {
  name                = "sf_transaction"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
//SF_Transaction Event Hub Rules
resource "azurerm_eventhub_authorization_rule" "eh_sf_transaction" {
  name                = "SendListenPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eh_sf_transaction.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}
//SF_Transaction_Status Event Hub
resource "azurerm_eventhub" "eh_sf_transaction_status" {
  name                = "sf_transaction_status"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
//SF_Transaction_status Event Hub Rules
resource "azurerm_eventhub_authorization_rule" "eh_sf_transaction_status" {
  name                = "SendListenPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eh_sf_transaction_status.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}
//Twillio Event Hub
resource "azurerm_eventhub" "eh_twillio" {
  name                = "twillio"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
//Twillio Event Hub Rules
resource "azurerm_eventhub_authorization_rule" "eh_twillio" {
  name                = "SendListenPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  eventhub_name       = azurerm_eventhub.eh_twillio.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = false
}
//Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.client}${var.application}clamav${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_tier
  admin_enabled       = true
}
//App Service Plan for Container App
resource "azurerm_app_service_plan" "serviceplan_linux" {
  name                = (var.hosting_plan == "ServicePlan") ? "${local.name}${var.hosting_plan}linuxplan" : var.hosting_plan
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = var.serviceplan_tier
    size = var.serviceplan_size
  }
}
//Web App for Containers
resource "azurerm_app_service" "containerapp" {
  name                = "${var.client}${var.application}clamav${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.serviceplan_linux.id
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
    //Application Insights Configuration
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = "${azurerm_application_insights.insights.instrumentation_key}"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = "${azurerm_application_insights.insights.connection_string}"
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "APPLICATIONINSIGHTS_CONFIGURATION_CONTENT"       = ""
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~3"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "disabled"
    "SnapshotDebugger_EXTENSION_VERSION"              = "disabled"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
  }
  site_config {
    linux_fx_version = "DOCKER|${var.client}${var.application}clamav${var.environment}.azurecr.io/clamav:latest"
    always_on        = "true"
  }
}
//Radis Cache
resource "azurerm_redis_cache" "redis" {
  name                = "${var.client}${var.application}radis${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = "1"
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  redis_configuration {
  }
}