output "master_private_ips" {
  value = aws_instance.masters[*].private_ip
}
