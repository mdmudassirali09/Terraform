variable "client" {
  type        = string
  description = "Client name"
}

variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "rg_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Resource group location"
}

variable "server_name" {
  type        = string
  description = "Server name"
}

variable "admin_login" {
  type        = string
  description = "Administrator"
}

variable "admin_password" {
  type        = string
  description = "Admin password"
}

variable "user_login" {
  type        = string
  description = "User"
}

variable "user_password" {
  type        = string
  description = "User password"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_tier" {
  type        = string
  description = "Database tier"
}

variable "db_size" {
  type        = string
  description = "Database size"
}

variable "hosting_plan" {
  type        = string
  description = "App Service Plan Name"
}

variable "serviceplan_tier" {
  type        = string
  description = "Service Plan tier"
}

variable "serviceplan_size" {
  type        = string
  description = "Service Plan size"
}

variable "account_tier" {
  type        = string
  description = "Storage account Tier"
}

variable "acr_tier" {
  type        = string
  description = "Azure Container Registry Tier"
}

variable "front_app_service" {
  type        = string
  description = "Front-end App Service Name"
}

variable "redis_tier" {
  type        = string
  description = "Redis Cache Tier"
}

variable "redis_family" {
  type        = string
  description = "Redis Cache Family"
}

variable "redis_capacity" {
  type        = number
  description = "Redis Cache Capacity"
}

variable "client_id" {
  type        = string
  description = "Client ID"
}

variable "client_secret" {
  type        = string
  description = "Client Secret"
}

variable "spa_client_id" {
  type        = string
  description = "Spa Client ID"
}

variable "issuer" {
  type        = string
  description = "issuer"
}

variable "jwt_refresh_secret" {
  type        = string
  description = "jwt_refresh_secret"
}

variable "jwt_secret" {
  type        = string
  description = "jwt_secret"
}