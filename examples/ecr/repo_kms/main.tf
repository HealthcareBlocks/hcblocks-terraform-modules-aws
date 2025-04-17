terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

module "ecr_repo" {
  source      = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ecr/v1.1.0"
  name_prefix = "ecr-with-custom-key"
  kms_key_id  = aws_kms_key.ecr.id
}

resource "aws_kms_key" "ecr" {
  description             = "ecr-repo-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

output "repo_arn" {
  value = module.ecr_repo.repo_arn
}
