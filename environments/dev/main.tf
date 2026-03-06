module "platform" {
  source = "../../modules/platform"

  project     = var.project
  environment = var.environment

  region = var.region
}
