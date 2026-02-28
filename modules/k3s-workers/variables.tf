variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "worker_count" {
  type = number
}

variable "cluster_token" {
  type      = string
  sensitive = true
}

variable "k3s_version" {
  type = string
}

variable "api_endpoint" {
  type = string
}

variable "ami_name_pattern" {
  type = string
}

variable "node_labels" {
  description = "Labels to apply to worker nodes"
  type        = map(string)
  default     = {}
}
