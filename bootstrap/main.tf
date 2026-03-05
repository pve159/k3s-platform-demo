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
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:pve159/k3s-platform-demo:*"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:${var.terraform_user}"
        }
        Action = "sts:AssumeRole"
      }
    ]
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

      #################################################
      # EC2 / VPC infrastructure
      #################################################

      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Create*",
          "ec2:Modify*",
          "ec2:Delete*",
          "ec2:Attach*",
          "ec2:Detach*",
          "ec2:RunInstances",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },

      #################################################
      # IAM roles used by Terraform
      #################################################

      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k3s-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-execution-role"
        ]
      },

      #################################################
      # IAM policy management
      #################################################

      {
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicy",
          "iam:DeletePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
      },

      #################################################
      # OIDC provider for GitHub
      #################################################

      {
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      },

      #################################################
      # Terraform S3 backend
      #################################################

      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:Get*"
        ]
        Resource = aws_s3_bucket.tf_state.arn
      },

      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.tf_state.arn}/*"
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
        Sid    = "AllowTerraformRoleObjectAccess"
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
        Sid    = "AllowTerraformRoleListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.terraform_execution_role.arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.tf_state.arn
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
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

#################################################
# GitHub OIDC Provider
#################################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = local.common_tags
}
