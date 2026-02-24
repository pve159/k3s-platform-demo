output "terraform_role_arn" {
  value = aws_iam_role.terraform_execution_role.arn
}

output "bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}