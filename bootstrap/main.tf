#################################################
# Account info
#################################################

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_name}-tfstate"
  common_tags = {
    Project = var.project_name
    Managed = "terraform-bootstrap"
  }
}

#################################################
# S3 Bucket for Terraform state
#################################################

resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name
  lifecycle {
    prevent_destroy = true
  }
  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

#################################################
# Enable Versioning
#################################################

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

#################################################
# Enable Encryption (SSE-S3 AES256)
#################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#################################################
# Lifecycle rule (cleanup old versions)
#################################################

resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

#################################################
# Block Public Access
#################################################

resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#################################################
# Terraform execution role
#################################################

resource "aws_iam_role" "terraform_execution_role" {
  name = "terraform-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

#################################################
# Add custom Terraform policy
#################################################

resource "aws_iam_policy" "terraform_infra_policy" {
  name = "terraform-infra-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # =========================
      # EC2 & Networking
      # =========================
      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      # =========================
      # IAM (minimal)
      # =========================
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRole"
        ]
        Resource = "*"
      },
      # =========================
      # S3 backend state
      # =========================
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::k3s-platform-demo-tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::k3s-platform-demo-tfstate/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.terraform_execution_role.name
  policy_arn = aws_iam_policy.terraform_infra_policy.arn
}

#################################################
# Restrict bucket access to Terraform role
#################################################

resource "aws_s3_bucket_policy" "tf_state_policy" {
  bucket = aws_s3_bucket.tf_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowTerraformRoleObjectAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.terraform_execution_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.tf_state.arn}/*"
      },
      {
        Sid = "AllowTerraformRoleListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.terraform_execution_role.arn
        }
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.tf_state.arn
      },
      {
        Sid = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
