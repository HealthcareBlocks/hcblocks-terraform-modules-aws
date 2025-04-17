terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.3.0"

  cidr_block                        = "10.10.0.0/16"
  vpc_name                          = "vpc"
  vpc_endpoint_interfaces_to_enable = ["lambda"]
}

module "lambda" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=lambda_function/v1.2.0"

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

module "cloudwatch_logs" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=cloudwatch_logs/v1.1.0"

  log_group_name = "/state_machines"
}

module "step_functions" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=step_functions/v1.2.0"

  allowed_lambda_functions_to_invoke = [
    module.lambda.lambda_function_arn,
  ]

  cloudwatch_log_group = module.cloudwatch_logs.log_group_arn
  publish              = true
  state_machine_name   = "helloworld"

  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Type": "Task",
      "Resource": "${module.lambda.lambda_function_arn}",
      "End": true
    }
  }
}
EOF
}
