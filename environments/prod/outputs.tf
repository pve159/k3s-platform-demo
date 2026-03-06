output "k3s_cluster_token" {
  description = "K3s cluster join token"
  value       = module.platform.k3s_cluster_token
  sensitive   = true
}

output "k3s_api_endpoint" {
  description = "API endpoint for K3s cluster"
  value       = module.platform.k3s_api_endpoint
}

output "kubeconfig_fetch_command" {
  description = "Command to fetch kubeconfig from first master via bastion"
  value       = module.platform.kubeconfig_fetch_command
}

output "kubernetes_tunnel" {
  description = "SSH tunnel command to access Kubernetes API"
  value       = module.platform.kubernetes_tunnel
}
