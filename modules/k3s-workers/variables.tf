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

variable "private_subnet_ids" {
  description = "List of private subnet IDs (one per availability zone)"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID attached to cluster nodes (masters/workers)"
  type        = string
}

variable "azs" {
  description = "List of availability zones used by the VPC"
  type        = list(string)
}

############################################################
# Compute Configuration
############################################################

variable "instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name used to access EC2 instances"
  type        = string
}

variable "ami_name_pattern" {
  description = "AMI name pattern used to dynamically select the Ubuntu image"
  type        = string
}

############################################################
# Scaling Configuration
############################################################

variable "worker_count_per_az" {
  description = "Number of worker nodes deployed per availability zone"
  type        = number
  default     = 1
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
  description = "K3s version to install on cluster nodes"
  type        = string
}

variable "api_endpoint" {
  description = "K3s API endpoint (bastion public IP or load balancer DNS)"
  type        = string
}

variable "node_labels" {
  description = "Custom Kubernetes labels applied to worker nodes"
  type        = map(string)
  default     = {}
}
