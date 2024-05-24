locals {
  filename_without_extension = split(".", var.filename)[0]
  output_path                = "${path.module}/${local.filename_without_extension}.zip"
  create_vpc_resources       = length(var.subnet_ids) > 0
}

data "archive_file" "this" {
  type        = "zip"
  source_file = var.filename
  output_path = local.output_path
}

resource "aws_lambda_function" "this" {
  architectures    = var.architectures
  description      = var.description
  filename         = local.output_path
  function_name    = var.function_name
  handler          = var.function_handler
  layers           = var.layers
  memory_size      = var.memory_size
  publish          = var.publish_new_version
  role             = aws_iam_role.this.arn
  runtime          = var.runtime
  source_code_hash = data.archive_file.this.output_base64sha256
  tags             = var.tags
  timeout          = var.timeout

  dynamic "environment" {
    for_each = length(keys(var.env_variables)) > 0 ? [true] : []

    content {
      variables = var.env_variables
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [true] : []

    content {
      mode = var.tracing_mode
    }
  }

  dynamic "vpc_config" {
    for_each = local.create_vpc_resources ? [true] : []

    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }
}

# -----------------------------------------------------------------------------
# IAM PERMISSIONS
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "lambda-"
  description        = "Allows Lambda function to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution_role_policy" {
  count      = local.create_vpc_resources ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray_daemon_write_access_policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_attached_other_policies" {
  count      = length(var.additional_iam_policies)
  role       = aws_iam_role.this.name
  policy_arn = var.additional_iam_policies[count.index]
}

# https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#configuration-vpc-permissions
data "aws_iam_policy_document" "lambda_vpc_permissions" {
  count = local.create_vpc_resources ? 1 : 0

  statement {

    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "lambda_vpc_permissions" {
  count       = local.create_vpc_resources ? 1 : 0
  name_prefix = "lambda-vpc-"
  policy      = data.aws_iam_policy_document.lambda_vpc_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  count      = local.create_vpc_resources ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_vpc_permissions[0].arn
}
