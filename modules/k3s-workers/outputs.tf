output "worker_private_ips" {
  value = [
    for instance in aws_instance.workers :
    instance.private_ip
  ]
}

output "worker_ids" {
  value = [
    for instance in aws_instance.workers :
    instance.id
  ]
}
