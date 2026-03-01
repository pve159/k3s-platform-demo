data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

resource "aws_key_pair" "this" {
  key_name   = "${local.project}-${local.environment}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-key"
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
  source = "../../modules/network"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  allowed_admin_cidr   = "${chomp(data.http.my_ip.response_body)}/32"
}

module "bastion" {
  source = "../../modules/bastion"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_id                    = module.network.vpc_id
  public_subnet_id          = module.network.public_subnet_id
  bastion_security_group_id = module.network.bastion_security_group_id

  key_name           = aws_key_pair.this.key_name
  instance_type      = var.bastion_instance_type
  allowed_admin_cidr = "${chomp(data.http.my_ip.response_body)}/32"

  master_private_ips = module.k3s_masters.master_private_ips

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

module "k3s_masters" {
  source = "../../modules/k3s-masters"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  cluster_security_group_id = module.network.cluster_security_group_id

  instance_type = var.master_instance_type
  key_name      = aws_key_pair.this.key_name
  master_count  = 2
  cluster_token = random_password.k3s_cluster_token.result
  tls_san       = "127.0.0.1"
  k3s_version   = "v1.29.6+k3s1"

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

module "k3s_workers" {
  source = "../../modules/k3s-workers"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  private_subnet_ids        = module.network.private_subnet_ids
  azs                       = var.azs
  cluster_security_group_id = module.network.cluster_security_group_id

  instance_type       = var.worker_instance_type
  key_name            = aws_key_pair.this.key_name
  worker_count_per_az = 2

  cluster_token = random_password.k3s_cluster_token.result
  k3s_version   = var.k3s_version
  api_endpoint  = module.bastion.bastion_public_ip

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"

  node_labels = {
    role = "worker"
    pool = "general"
  }
}
