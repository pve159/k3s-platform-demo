output "k3s_cluster_token" {
  description = "K3s cluster join token"
  value       = random_password.k3s_cluster_token.result
  sensitive   = true
}

output "k3s_api_endpoint" {
  description = "API endpoint for K3s cluster (via SSH tunnel)"
  value       = "https://127.0.0.1:6443"
}

output "kubeconfig_fetch_command" {
  description = "Command to fetch kubeconfig from first master via bastion"
  value       = <<EOT
ssh -J ubuntu@${module.bastion.bastion_public_ip} ubuntu@${module.k3s_masters.master_private_ips[0]} "sudo cat /etc/rancher/k3s/k3s.yaml"
EOT
}
