############################################################
# Provider & IAM Configuration
############################################################

variable "region" {
  description = "AWS region where infrastructure resources will be deployed"
  type        = string
  default     = "eu-west-3"
}

variable "terraform_role_arn" {
  description = "IAM role ARN assumed by Terraform for infrastructure provisioning"
  type        = string
}

############################################################
# Networking Configuration
############################################################

variable "vpc_cidr" {
  description = "CIDR block assigned to the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (bastion subnet)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "azs" {
  description = "List of availability zones used for subnet distribution"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

############################################################
# Compute Configuration
############################################################

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "master_instance_type" {
  description = "EC2 instance type for k3s control-plane (master) nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for k3s worker nodes"
  type        = string
  default     = "t3.small"
}

############################################################
# Kubernetes Configuration
############################################################

variable "k3s_version" {
  description = "Pinned version of k3s installed on cluster nodes"
  type        = string
  default     = "v1.29.6+k3s1"
}

############################################################
# SSH Configuration
############################################################

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key used to create the EC2 key pair"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
