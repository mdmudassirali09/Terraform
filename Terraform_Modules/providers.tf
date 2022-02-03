provider "azurerm" {
  features {}
  subscription_id = "f1aa2e52-404f-4a79-88d2-4b776a8d3965"
  client_id       = "34f1ac3b-f923-4e75-818b-1f654164134b"
  client_secret   = "pcJ7Q~duMsGU6Y.NO1BaSflZ3fr6-0kUQI5ge"
  tenant_id       = "2f267b42-7074-43d7-927f-6cd5c2ba4275"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.90.0"
    }
  }
}