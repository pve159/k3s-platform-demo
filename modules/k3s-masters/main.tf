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
# Security Group
################################################################################

resource "aws_security_group" "cluster" {
  name   = "${var.project}-${var.environment}-cluster-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Cluster internal communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Kubernetes API from bastion"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # On restreindra ensuite
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-cluster-sg"
  })
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
  vpc_security_group_ids = [aws_security_group.cluster.id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    cluster_token = var.cluster_token
    is_first      = count.index == 0
    first_master  = aws_instance.masters[0].private_ip
    tls_san       = var.tls_san
    k3s_version   = var.k3s_version
  })

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-master-${count.index}"
  })
}
