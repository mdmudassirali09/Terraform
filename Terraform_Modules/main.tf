data "azurerm_resource_group" "rg" {
  name = "${var.client}${var.app}devRG"
}

module "front_app" {
  source            = "./modules/front_app_service"
  rg_name           = data.azurerm_resource_group.rg.name
  service_plan_name = "${var.client}${var.app}LinuxPlan"
  name              = "${var.client}${var.app}"

}

module "api_app" {
  source            = "./modules/api_app_service"
  rg_name           = data.azurerm_resource_group.rg.name
  service_plan_name = module.front_app.service_plan_name
  name              = "${var.client}${var.app}api"
  prodConfig        = var.config
  depends_on = [
    module.front_app
  ]
}

module "twilio_app" {
  source            = "./modules/twilio_function_app"
  rg_name           = data.azurerm_resource_group.rg.name
  service_plan_name = "${var.client}${var.app}WindowsPlan"
  name              = "${var.client}${var.app}-twilio-integration"
  strgacc_name      = "${var.client}${var.app}twilio"
}
