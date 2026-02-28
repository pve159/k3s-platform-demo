module "network" {
  source = "../../modules/network"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "bastion" {
  source = "../../modules/bastion"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id

  key_name         = var.key_name
  instance_type    = var.bastion_instance_type
  allowed_ssh_cidr = var.allowed_ssh_cidr

  master_private_ips = module.k3s_masters.master_private_ips

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

resource "aws_route" "private_nat" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"

  instance_id = module.bastion.nat_instance_id
}

module "k3s_masters" {
  source = "../../modules/k3s-masters"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  instance_type = var.master_instance_type
  key_name      = var.key_name
  master_count  = 2
  cluster_token = var.cluster_token
  tls_san       = module.bastion.bastion_public_ip
  k3s_version   = "v1.29.6+k3s1"

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

module "k3s_workers" {
  source = "../../modules/k3s-workers"

  project     = local.project
  environment = local.environment
  common_tags = local.common_tags

  private_subnet_ids        = module.network.private_subnet_ids
  cluster_security_group_id = module.k3s_masters.security_group_id

  instance_type = var.worker_instance_type
  key_name      = var.key_name
  worker_count  = 2

  cluster_token = var.cluster_token
  k3s_version   = var.k3s_version

  api_endpoint  = module.bastion.bastion_public_ip

  ami_name_pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"

  node_labels = {
    role = "worker"
    pool = "general"
  }
}
