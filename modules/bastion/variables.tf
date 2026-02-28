variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID"
}

variable "key_name" {
  type        = string
  description = "SSH key name"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH"
}

variable "master_private_ips" {
  type        = list(string)
  description = "Private IPs of k3s masters for HAProxy"
}

variable "ami_name_pattern" {
  type        = string
  description = "AMI name pattern for lookup"
}
