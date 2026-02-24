#################################################
# S3 Bucket for Terraform state
#################################################

resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.project_name}-tfstate"

  tags = {
    Name    = "${var.project_name}-tfstate"
    Project = var.project_name
    Managed = "terraform-bootstrap"
  }
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
# Enable Server-side encryption
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
# Block public access
#################################################

resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#################################################
# DynamoDB table for state locking
#################################################

resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.project_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-tf-locks"
    Project = var.project_name
    Managed = "terraform-bootstrap"
  }
}
