terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "ecr_repo" {
  source      = "../../../ecr"
  name_prefix = "ecr-default"
}

output "repo_arn" {
  value = module.ecr_repo.repo_arn
}
