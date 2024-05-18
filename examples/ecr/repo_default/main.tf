terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "ecr_repo" {
  source      = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ecr/v1.0.0"
  name_prefix = "ecr-default"
}

output "repo_arn" {
  value = module.ecr_repo.repo_arn
}
