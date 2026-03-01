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
  description = "Common tags applied to all resources"
  type        = map(string)
}

############################################################
# Networking
############################################################

variable "vpc_id" {
  description = "VPC ID where master nodes are deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs used to distribute master nodes"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID attached to master nodes"
  type        = string
}

############################################################
# Compute Configuration
############################################################

variable "instance_type" {
  description = "EC2 instance type for master nodes"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name used to access master instances"
  type        = string
}

variable "ami_name_pattern" {
  description = "AMI name pattern used to dynamically select the Ubuntu image"
  type        = string
}

############################################################
# Scaling Configuration
############################################################

variable "master_count" {
  description = "Number of k3s master (control-plane) nodes to deploy"
  type        = number
}

############################################################
# K3s Cluster Configuration
############################################################

variable "cluster_token" {
  description = "Shared secret token used for k3s cluster node registration"
  type        = string
  sensitive   = true
}

variable "k3s_version" {
  description = "Pinned k3s version installed on master nodes"
  type        = string
}

variable "tls_san" {
  description = "Public load balancer IP or DNS added to TLS SAN for API server"
  type        = string
}
