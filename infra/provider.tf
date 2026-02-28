terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.32"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
  }
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.terraform_role_arn
  }
  default_tags {
    tags = {
      Managed = "terraform"
      Project = "k3s-platform-demo"
      Owner   = "Patrick Verschuere"
    }
  }
}