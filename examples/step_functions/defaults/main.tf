terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "../../../vpc"

  cidr_block                        = "10.10.0.0/16"
  vpc_name                          = "vpc"
  vpc_endpoint_interfaces_to_enable = ["lambda"]
}

module "lambda" {
  source = "../../../lambda_function"

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

module "cloudwatch_logs" {
  source = "../../../cloudwatch_logs"

  log_group_name = "/state_machines"
}

module "step_functions" {
  source = "../../../step_functions"

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
