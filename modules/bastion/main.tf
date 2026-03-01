################################################################################
# AMI lookup
################################################################################

data "aws_ami" "this" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# Elastic IP + association
################################################################################

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-bastion-eip"
  })
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}

################################################################################
# EC2 Instance (NAT + HAProxy)
################################################################################

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.bastion_security_group_id]

  source_dest_check = false

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    master_private_ips = var.master_private_ips
  })
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-bastion"
  })
}
