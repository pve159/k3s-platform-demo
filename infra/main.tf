################################################################################
# Data
################################################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ubuntu_pattern]
  }
  owners = [var.ubuntu_owner]
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

################################################################################
# SSH key
################################################################################

resource "aws_key_pair" "demo-ssh-key" {
  key_name   = "demo-ssh-key"
  public_key = file(var.ssh_key_file)
}

################################################################################
# Network
################################################################################

### VPC

resource "aws_vpc" "demo-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "demo-vpc"
  }
}

### Elastic IP

resource "aws_eip" "demo-bastion-eip" {
  domain = "vpc"
}

resource "aws_eip_association" "demo-bastion-eipa" {
  allocation_id        = aws_eip.demo-bastion-eip.id
  network_interface_id = aws_network_interface.demo-bastion-eni.id
}

### Internet gateway

resource "aws_internet_gateway" "demo-gateway" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-gateway"
  }
}

### Public routes

resource "aws_route_table" "demo-public-rtb" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-gateway.id
  }
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-public-rtb"
  }
}

resource "aws_route_table_association" "demo-public-rtba" {
  route_table_id = aws_route_table.demo-public-rtb.id
  subnet_id      = aws_subnet.demo-public-subnet.id
}

### Private routes

resource "aws_route_table" "demo-private_rtb" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-private_rtb"
  }
}

resource "aws_route" "demo-private-nat-route" {
  route_table_id         = aws_route_table.demo-private_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.demo-bastion-eni.id
}

resource "aws_route_table_association" "demo-private_a-rtba" {
  route_table_id = aws_route_table.demo-private_rtb.id
  subnet_id      = aws_subnet.demo-private_a-subnet.id
}

resource "aws_route_table_association" "demo-private_b-rtba" {
  route_table_id = aws_route_table.demo-private_rtb.id
  subnet_id      = aws_subnet.demo-private_b-subnet.id
}

### Public subnet

resource "aws_subnet" "demo-public-subnet" {
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "demo-public-subnet"
  }
  vpc_id = aws_vpc.demo-vpc.id
}

### Private subnets

resource "aws_subnet" "demo-private_a-subnet" {
  cidr_block        = var.private_a_subnet_cidr
  availability_zone = "${var.region}a"
  tags = {
    Name = "demo-private_a-subnet"
  }
  vpc_id = aws_vpc.demo-vpc.id
}

resource "aws_subnet" "demo-private_b-subnet" {
  cidr_block        = var.private_b_subnet_cidr
  availability_zone = "${var.region}b"
  tags = {
    Name = "demo-private_b-subnet"
  }
  vpc_id = aws_vpc.demo-vpc.id
}

################################################################################
# EC2 - Bastion
################################################################################

resource "aws_network_interface" "demo-bastion-eni" {
  subnet_id       = aws_subnet.demo-public-subnet.id
  private_ips     = [var.private_ip_bastion]
  security_groups = [aws_security_group.demo-bastion-sg.id]
  # Required for NAT functionality
  source_dest_check = false
  tags = {
    Name = "demo-bastion-eni"
  }
}

resource "aws_security_group" "demo-bastion-sg" {
  egress {
    description = "Allow all outbound"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from VPC (HAProxy)"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Allow HTTP from VPC (HAProxy)"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Allow SSH only from my IP"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
  ingress {
    description = "Allow Kubernetes API from private subnets"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.private_a_subnet_cidr, var.private_b_subnet_cidr]
  }
  name        = "demo-bastion-sg"
  description = "demo-bastion-sg"
  vpc_id      = aws_vpc.demo-vpc.id
}

resource "aws_instance" "demo-bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_bastion
  key_name      = aws_key_pair.demo-ssh-key.key_name
  tags = {
    Name = "demo-bastion"
  }
  primary_network_interface {
    network_interface_id = aws_network_interface.demo-bastion-eni.id
  }
  iam_instance_profile = aws_iam_instance_profile.demo-bastion-profile.name
  user_data = templatefile("user_data_bastion.sh", {
    MASTER_A_IP = aws_instance.demo-k3s-master_a.private_ip
    MASTER_B_IP = aws_instance.demo-k3s-master_b.private_ip
  })
  user_data_replace_on_change = true
}

################################################################################
# EC2 - K3s
################################################################################

resource "random_password" "demo-k3s-token" {
  length  = 40
  special = false
}

resource "aws_security_group" "demo-k3s-sg" {
  egress {
    description = "Allow all outbound"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "Allow SSH only from bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.demo-bastion-sg.id]
  }
  /*
  ingress {
    description = "Allow Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Allow Flannel VXLAN backend"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }
  */
  ingress {
    description = "Allow internal cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description     = "Allow Kubernetes API from bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.demo-bastion-sg.id]
  }
  name        = "demo-k3s-sg"
  description = "demo-k3s-sg"
  vpc_id      = aws_vpc.demo-vpc.id
}

resource "aws_instance" "demo-k3s-master_a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_k3s_master
  key_name               = aws_key_pair.demo-ssh-key.key_name
  subnet_id              = aws_subnet.demo-private_a-subnet.id
  vpc_security_group_ids = [aws_security_group.demo-k3s-sg.id]
  user_data = templatefile("user_data_master_a.sh", {
    K3S_TOKEN = random_password.demo-k3s-token.result
    LB_IP     = var.private_ip_bastion
  })
  user_data_replace_on_change = true
  tags = {
    Name = "demo-k3s-master_a"
  }
}

resource "aws_instance" "demo-k3s-worker_a" {
  count                  = var.nb_workers
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_k3s_worker
  key_name               = aws_key_pair.demo-ssh-key.key_name
  subnet_id              = aws_subnet.demo-private_a-subnet.id
  vpc_security_group_ids = [aws_security_group.demo-k3s-sg.id]
  user_data = templatefile("user_data_worker.sh", {
    K3S_TOKEN = random_password.demo-k3s-token.result
    LB_IP     = var.private_ip_bastion
  })
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.demo-k3s-master_a]
  tags = {
    Name = "demo-k3s-worker_a-${count.index}"
  }
}

resource "aws_instance" "demo-k3s-master_b" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_k3s_master
  key_name               = aws_key_pair.demo-ssh-key.key_name
  subnet_id              = aws_subnet.demo-private_b-subnet.id
  vpc_security_group_ids = [aws_security_group.demo-k3s-sg.id]
  user_data = templatefile("user_data_master_b.sh", {
    K3S_TOKEN = random_password.demo-k3s-token.result
    LB_IP     = var.private_ip_bastion
  })
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.demo-k3s-master_a]
  tags = {
    Name = "demo-k3s-master_b"
  }
}

resource "aws_instance" "demo-k3s-worker_b" {
  count                  = var.nb_workers
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_k3s_worker
  key_name               = aws_key_pair.demo-ssh-key.key_name
  subnet_id              = aws_subnet.demo-private_b-subnet.id
  vpc_security_group_ids = [aws_security_group.demo-k3s-sg.id]
  user_data = templatefile("user_data_worker.sh", {
    K3S_TOKEN = random_password.demo-k3s-token.result
    LB_IP     = var.private_ip_bastion
  })
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.demo-k3s-master_b]
  tags = {
    Name = "demo-k3s-worker_b-${count.index}"
  }
}

############################################
# IAM Role (Minimal – extend later if needed)
############################################

resource "aws_iam_role" "demo-bastion-role" {
  name = "demo-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "demo-bastion-profile" {
  name = "demo-bastion-profile"
  role = aws_iam_role.demo-bastion-role.name
  lifecycle { create_before_destroy = true }
}
