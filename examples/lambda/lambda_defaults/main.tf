terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

# -----------------------------------------------------------------------------
# Example of Lambda function deployed to a VPC (an AWS recommended practice)
# -----------------------------------------------------------------------------

module "lambda" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=lambda_function/v1.1.0"

  filename           = "${path.module}/helloworld.py"
  function_name      = "helloworld"
  function_handler   = "helloworld.lambda_handler"
  runtime            = "python3.8"
  security_group_ids = [aws_security_group.lambda_helloworld.id]
  subnet_ids         = module.vpc.private_subnet_ids
  #publish_new_version = true

  env_variables = {
    foo = "bar"
  }
}

module "vpc" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.2.0"

  cidr_block                        = "10.10.0.0/16"
  vpc_name                          = "vpc"
  vpc_endpoint_interfaces_to_enable = ["lambda"]
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

output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "lambda_function_version" {
  value = module.lambda.lambda_function_version
}

# -----------------------------------------------------------------------------
# Example of Lambda function with non-VPC deployment
# -----------------------------------------------------------------------------

module "lambda_deployed_outside_of_vpc" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=lambda_function/v1.1.0"

  filename         = "${path.module}/helloworld2.py"
  function_name    = "helloworld-2"
  function_handler = "helloworld.lambda_handler"
  runtime          = "python3.8"
  #publish_new_version = true
}

output "lambda_non_vpc_function_arn" {
  value = module.lambda_deployed_outside_of_vpc.lambda_function_arn
}

output "lambda__non_vpc_function_version" {
  value = module.lambda_deployed_outside_of_vpc.lambda_function_version
}
