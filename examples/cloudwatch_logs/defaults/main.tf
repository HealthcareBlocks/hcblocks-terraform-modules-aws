terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

module "cloudwatch_logs" {
  source         = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=cloudwatch_logs/v1.1.0"
  log_group_name = "/app/prod"
}
