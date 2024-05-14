terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "../../../vpc"

  cidr_block = "10.10.0.0/16"
  vpc_name   = "vpc-with-defaults"
}
