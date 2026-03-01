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
# Networking
############################################################

variable "vpc_id" {
  description = "VPC ID where the bastion host is deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where the bastion instance is launched"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID attached to the bastion instance"
  type        = string
}

############################################################
# Compute Configuration
############################################################

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name used to access the bastion instance"
  type        = string
}

variable "ami_name_pattern" {
  description = "AMI name pattern used to dynamically select the Ubuntu image"
  type        = string
}

############################################################
# Security
############################################################

variable "allowed_admin_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
}

############################################################
# HAProxy Configuration
############################################################

variable "master_private_ips" {
  description = "List of private IP addresses of k3s master nodes used by HAProxy"
  type        = list(string)
}
