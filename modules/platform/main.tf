data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  ssh_ip = var.ssh_allowed_ip != "" ? var.ssh_allowed_ip : chomp(data.http.my_ip.response_body)

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.common_tags
  )
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project}-${var.environment}-key"
  public_key = file("${path.module}/../../keys/cluster.pub")

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-key"
  })
}

resource "random_password" "k3s_cluster_token" {
  length  = 40
  special = false
}

resource "aws_route" "private_nat" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"

  network_interface_id = module.bastion.primary_network_interface_id
}

module "network" {
  source = "../network"

  project     = var.project
  environment = var.environment
  common_tags = local.tags

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs

  allowed_admin_cidr = "${local.ssh_ip}/32"
}

module "bastion" {
  source = "../bastion"

  project     = var.project
  environment = var.environment
  common_tags = local.tags

  vpc_id                    = module.network.vpc_id
  bastion_private_ip        = var.bastion_private_ip
  public_subnet_id          = module.network.public_subnet_id
  bastion_security_group_id = module.network.bastion_security_group_id

  key_name      = aws_key_pair.this.key_name
  instance_type = var.bastion_instance_type

  allowed_admin_cidr = "${local.ssh_ip}/32"

  master_private_ips = module.k3s_masters.master_private_ips

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

module "k3s_masters" {
  source = "../k3s-masters"

  project     = var.project
  environment = var.environment
  common_tags = local.tags

  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  cluster_security_group_id = module.network.cluster_security_group_id

  instance_type = var.master_instance_type
  key_name      = aws_key_pair.this.key_name

  master_count  = 2
  cluster_token = random_password.k3s_cluster_token.result
  tls_san       = var.bastion_private_ip
  k3s_version   = var.k3s_version

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

module "k3s_workers" {
  source = "../k3s-workers"

  project     = var.project
  environment = var.environment
  common_tags = local.tags

  private_subnet_ids        = module.network.private_subnet_ids
  azs                       = var.azs
  cluster_security_group_id = module.network.cluster_security_group_id

  instance_type       = var.worker_instance_type
  key_name            = aws_key_pair.this.key_name
  worker_count_per_az = 2

  cluster_token = random_password.k3s_cluster_token.result
  k3s_version   = var.k3s_version
  api_endpoint  = var.bastion_private_ip

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"

  node_labels = {
    role = "worker"
    pool = "general"
  }
}
