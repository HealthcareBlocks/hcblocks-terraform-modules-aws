terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.2.0"

  cidr_block              = "10.10.0.0/16"
  private_subnets_enabled = false
  vpc_name                = "vpc-public-subnets-only"
}
