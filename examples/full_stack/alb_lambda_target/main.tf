terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.1.0"
  cidr_block = "10.100.0.0/16"
  vpc_name   = "vpc-prod"

  vpc_endpoint_interfaces_to_enable = ["lambda"]
}

module "log_bucket" {
  source                            = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.0.0"
  bucket_prefix                     = "logs"
  enable_load_balancer_log_delivery = true
  force_destroy                     = true # set to false in production environments
}

# created and validated outside of Terraform
data "aws_acm_certificate" "test" {
  domain = "REPLACE-WITH-DOMAIN"
}

module "alb" {
  source                     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=alb/v1.0.0"
  acm_certificate            = data.aws_acm_certificate.test.arn
  enable_deletion_protection = false # set to true in production environments
  logs_bucket                = module.log_bucket.bucket_name
  subnets                    = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.id

  listeners = {
    https = {
      forward = {
        target_group_key = "lambda"
      }
    }
  }

  target_groups = {
    lambda = {
      name_prefix                        = "ltg-"
      target_type                        = "lambda"
      lambda_multi_value_headers_enabled = true

      health_check = {
        enabled = false
      }
    }
  }

  target_group_members_lambda = {
    hello_world_lambda = {
      target_group_key     = "lambda"
      target_id            = module.lambda.lambda_function_arn
      lambda_function_name = module.lambda.lambda_function_name
    }
  }
}

module "lambda" {
  source              = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=lambda_function/v1.0.0"
  filename            = "${path.module}/helloworld.py"
  function_name       = "helloworld"
  function_handler    = "helloworld.lambda_handler"
  runtime             = "python3.8"
  security_group_ids  = [aws_security_group.lambda_helloworld.id]
  subnet_ids          = module.vpc.private_subnet_ids
  publish_new_version = true

  env_variables = {
    foo = "bar"
  }
}

resource "aws_security_group" "lambda_helloworld" {
  name_prefix = "lambda-helloworld-"
  description = "Lambda helloworld SG"
  vpc_id      = module.vpc.id

  egress {
    description = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
