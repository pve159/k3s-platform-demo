locals {
  project     = "k3s-platform"
  environment = "prod"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
