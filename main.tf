data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sfn_state_machine" "this" {
  definition = var.definition
  name       = var.state_machine_name
  publish    = var.publish
  role_arn   = aws_iam_role.this.arn
  tags       = var.tags
  type       = var.state_machine_type

  logging_configuration {
    include_execution_data = var.logs_include_execution_data
    level                  = var.log_level
    log_destination        = "${var.cloudwatch_log_group}:*"
  }

  tracing_configuration {
    enabled = var.enable_tracing_configuration
  }
}

# -----------------------------------------------------------------------------
# IAM ROLE
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "statemachine-"
  description        = "Allows State Machine ${var.state_machine_name} to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# -----------------------------------------------------------------------------
# CLOUDWATCH LOGS PERMISSIONS
# -----------------------------------------------------------------------------

# https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html#cloudwatch-iam-policy
data "aws_iam_policy_document" "cwlogs_permissions" {
  statement {

    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "cwlogs_permissions_policy" {
  name   = "cwlogs_permissions"
  policy = data.aws_iam_policy_document.cwlogs_permissions.json
}

resource "aws_iam_role_policy_attachment" "cwlogs_permissions_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.cwlogs_permissions_policy.arn
}

# -----------------------------------------------------------------------------
# AWS XRAY PERMISSIONS
# -----------------------------------------------------------------------------

# https://docs.aws.amazon.com/step-functions/latest/dg/xray-iam.html
data "aws_iam_policy_document" "xray_permissions" {
  count = var.enable_tracing_configuration == true ? 1 : 0

  statement {

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "xray_permissions_policy" {
  count  = var.enable_tracing_configuration == true ? 1 : 0
  name   = "xray_permissions"
  policy = data.aws_iam_policy_document.xray_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "xray_permissions_policy" {
  count      = var.enable_tracing_configuration == true ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.xray_permissions_policy[0].arn
}

# -----------------------------------------------------------------------------
# LAMBDA PERMISSIONS
# -----------------------------------------------------------------------------

# https://docs.aws.amazon.com/step-functions/latest/dg/lambda-iam.html
data "aws_iam_policy_document" "lambda_permissions" {
  count = length(var.allowed_lambda_functions_to_invoke) > 1 ? 1 : 0

  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = var.allowed_lambda_functions_to_invoke
  }
}

resource "aws_iam_policy" "lambda_permissions_policy" {
  count  = length(var.allowed_lambda_functions_to_invoke) > 1 ? 1 : 0
  name   = "lambda_permissions"
  policy = data.aws_iam_policy_document.lambda_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "lambda_permissions_policy" {
  count      = length(var.allowed_lambda_functions_to_invoke) > 1 ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_permissions_policy[0].arn
}

# -----------------------------------------------------------------------------
# SQS PERMISSIONS
# -----------------------------------------------------------------------------

# https://docs.aws.amazon.com/step-functions/latest/dg/sqs-iam.html
data "aws_iam_policy_document" "sqs_permissions" {
  count = length(var.allowed_sqs_queues_to_call) > 1 ? 1 : 0

  statement {

    actions = [
      "sqs:SendMessage",
    ]

    resources = var.allowed_sqs_queues_to_call
  }
}

resource "aws_iam_policy" "sqs_permissions_policy" {
  count  = length(var.allowed_sqs_queues_to_call) > 1 ? 1 : 0
  name   = "sqs_permissions"
  policy = data.aws_iam_policy_document.sqs_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "sqs_permissions_policy" {
  count      = length(var.allowed_sqs_queues_to_call) > 1 ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.sqs_permissions_policy[0].arn
}

# -----------------------------------------------------------------------------
# OTHER IAM POLICIES TO ATTACH
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "other_attached_policies" {
  count      = length(var.additional_iam_policies)
  role       = aws_iam_role.this.name
  policy_arn = var.additional_iam_policies[count.index]
}
