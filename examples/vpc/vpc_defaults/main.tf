terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.3.0"

  cidr_block = "10.10.0.0/16"
  vpc_name   = "vpc-with-defaults"
}
