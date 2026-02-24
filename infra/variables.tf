################################################################################
# AWS credentials, region & availability zones
################################################################################

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-west-3"
  validation {
    condition     = var.region != ""
    error_message = "Region must not be empty."
  }
}
variable "terraform_role_arn" {
  type    = string
  default = ""
  validation {
    condition     = var.terraform_role_arn != ""
    error_message = "Role ARN must not be empty."
  }
}

################################################################################
# EC2 configuration
################################################################################

variable "instance_type_bastion" {
  type    = string
  default = "t3.micro"
}
variable "instance_type_k3s_master" {
  type    = string
  default = "t3.small"
}
variable "instance_type_k3s_worker" {
  type    = string
  default = "t3.micro"
}
variable "ubuntu_owner" {
  type    = string
  default = "099720109477"
} # Canonical
variable "ubuntu_pattern" {
  type    = string
  default = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}
variable "ssh_key_file" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
variable "nb_workers" {
  description = "Number of worker nodes per private subnet"
  type        = number
  default     = 2
  validation {
    condition     = var.nb_workers >= 1
    error_message = "HA setup requires at least one worker per subnet."
  }
}

################################################################################
# VPC configuration
################################################################################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Invalid VPC CIDR block."
  }
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Invalid public CIDR block."
  }
}
variable "private_a_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.private_a_subnet_cidr, 0))
    error_message = "Invalid private A CIDR block."
  }
}
variable "private_b_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
  validation {
    condition     = can(cidrhost(var.private_b_subnet_cidr, 0))
    error_message = "Invalid private B CIDR block."
  }
}
variable "private_ip_bastion" {
  type    = string
  default = "10.0.0.10"
  validation {
    condition     = can(cidrhost("${var.private_ip_bastion}/32", 0))
    error_message = "Invalid IP address format."
  }
}