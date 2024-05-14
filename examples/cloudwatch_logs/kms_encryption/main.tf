terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "cloudwatch_logs" {
  source = "../../../cloudwatch_logs"

  create_kms_key_and_policy = true
  log_group_name            = "/app/prod"
}
