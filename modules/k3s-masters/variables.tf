variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "master_count" {
  type = number
}

variable "cluster_token" {
  type      = string
  sensitive = true
}

variable "ami_name_pattern" {
  type = string
}

variable "k3s_version" {
  type        = string
  description = "Pinned k3s version"
}

variable "tls_san" {
  type        = string
  description = "Load balancer IP or DNS for TLS SAN"
}
