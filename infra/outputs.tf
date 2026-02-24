output "my_ip" {
  value = "${chomp(data.http.my_ip.response_body)}/32"
}

output "bastion_eip" {
  value = aws_eip.demo-bastion-eip.public_ip
}