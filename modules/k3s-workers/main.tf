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
# Compute worker layout
################################################################################

locals {

  worker_list = flatten([
    for az_index, az in var.azs : [
      for worker_index in range(var.worker_count_per_az) : {
        key       = "${az}-${worker_index}"
        az        = az
        subnet_id = var.private_subnet_ids[az_index]
        index     = worker_index
      }
    ]
  ])

  worker_map = {
    for worker in local.worker_list :
    worker.key => worker
  }

}

################################################################################
# EC2 Instance (K3s workers)
################################################################################

resource "aws_instance" "workers" {
  for_each = local.worker_map

  ami                    = data.aws_ami.this.id
  instance_type          = var.instance_type
  subnet_id              = each.value.subnet_id
  availability_zone      = each.value.az
  key_name               = var.key_name
  vpc_security_group_ids = [var.cluster_security_group_id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    cluster_token = var.cluster_token
    k3s_version   = var.k3s_version
    api_endpoint  = var.api_endpoint
    node_labels = join(",", [
      for k, v in var.node_labels :
      "${k}=${v}"
    ])
  })
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-worker-${each.value.az}-${each.value.index}"
  })

  lifecycle {
    create_before_destroy = true
  }
}
