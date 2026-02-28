output "worker_private_ips" {
  value = aws_instance.workers[*].private_ip
}
