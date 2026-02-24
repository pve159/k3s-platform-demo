variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name used for naming backend resources"
  type        = string
  default     = "k3s-platform-demo"
}