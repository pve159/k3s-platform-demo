plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  module = true
}

rule "aws_security_group_rule_invalid_cidr_blocks" {
  enabled = true
}
