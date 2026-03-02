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
# EC2 Instance (K3s masters)
################################################################################

resource "aws_instance" "masters" {
  count = var.master_count

  ami                    = data.aws_ami.this.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  key_name               = var.key_name
  vpc_security_group_ids = [var.cluster_security_group_id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    cluster_token = var.cluster_token
    is_first      = count.index == 0
    tls_san       = "127.0.0.1"
    k3s_version   = var.k3s_version
  })
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-master-${count.index}"
  })
}
