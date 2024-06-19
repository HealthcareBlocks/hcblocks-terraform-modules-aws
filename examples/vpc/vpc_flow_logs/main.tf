terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc_cloudwatch_flow_log" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.2.0"

  cidr_block              = "10.0.0.0/16"
  private_subnets_enabled = false
  vpc_name                = "vpc-cloudwatch-flow-log-test"
}

module "vpc_s3_flow_log" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.2.0"

  cidr_block              = "10.10.0.0/16"
  private_subnets_enabled = false
  vpc_name                = "vpc-s3-flow-log-test"

  flow_log_config = {
    s3_destination_enabled = true
    s3_bucket_arn          = module.flow_logs_bucket.bucket_arn
  }
}

module "vpc_multi_flow_log" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.2.0"

  cidr_block              = "10.20.0.0/16"
  private_subnets_enabled = false
  vpc_name                = "vpc-multi-flow-log-test"

  flow_log_config = {
    cw_logs_destination_enabled = true
    s3_destination_enabled      = true
    s3_bucket_arn               = module.flow_logs_bucket.bucket_arn
  }
}

module "flow_logs_bucket" {
  source                   = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.2.0"
  bucket_prefix            = "flow-logs"
  enable_flow_log_delivery = true
}
