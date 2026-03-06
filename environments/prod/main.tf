module "platform" {
  source = "../../modules/platform"

  project     = "k3s-platform"
  environment = "prod"

  region = var.region
}
