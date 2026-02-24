terraform {
  backend "s3" {
    bucket       = "k3s-platform-demo-tfstate"
    key          = "k3s-platform/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}