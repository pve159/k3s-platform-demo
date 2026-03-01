############################################################
# Project & Environment
############################################################

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all created resources"
  type        = map(string)
}

############################################################
# VPC Configuration
############################################################

variable "vpc_cidr" {
  description = "CIDR block assigned to the VPC"
  type        = string
}

############################################################
# Subnet Configuration
############################################################

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (bastion subnet)"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones used for subnet distribution"
  type        = list(string)
}

############################################################
# Security Configuration
############################################################

variable "allowed_admin_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
}
