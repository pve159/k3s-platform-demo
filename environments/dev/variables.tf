variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "k3s-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
