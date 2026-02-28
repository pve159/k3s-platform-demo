provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.terraform_role_arn
  }
}
