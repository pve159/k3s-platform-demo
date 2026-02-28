output "master_private_ips" {
  value = aws_instance.masters[*].private_ip
}

output "security_group_id" {
  value = aws_security_group.cluster.id
}
