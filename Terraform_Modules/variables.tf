variable "client" {
  type        = string
  description = "Client name"
}

variable "app" {
  type        = string
  description = "Application name"
}

variable "admin_login" {
  type        = string
  default     = "MsgAppAdmin"
  description = "Administrator"
}

variable "admin_password" {
  type        = string
  default     = "Password@123"
  description = "Admin password"
}

variable "config" {
  type        = map
  description = "Admin password"
}
