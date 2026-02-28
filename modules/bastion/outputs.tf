output "nat_instance_id" {
  description = "Instance ID of NAT/Bastion"
  value       = aws_instance.this.id
}

output "bastion_public_ip" {
  description = "Public IP of bastion"
  value       = aws_eip.this.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of bastion"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID of bastion"
  value       = aws_security_group.bastion.id
}
