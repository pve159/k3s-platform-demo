terraform {
  required_version = "~> 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.34"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}
