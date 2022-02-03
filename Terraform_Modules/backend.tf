terraform {
  backend "azurerm" {
    resource_group_name  = "TerraformRG"
    storage_account_name = "terraformstrgacc"
    container_name       = "tfstates-testing"
    key                  = "modules.tfstate"
  }
}
