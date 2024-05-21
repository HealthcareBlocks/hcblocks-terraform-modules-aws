data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# -----------------------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------------------

data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/ec2_instance_user_manager.rb"
  output_path = "${path.module}/ec2_instance_user_manager.zip"
}

resource "aws_lambda_function" "this" {
  filename         = "${path.module}/ec2_instance_user_manager.zip"
  function_name    = "ec2-instance-user-manager"
  handler          = "ec2_instance_user_manager.lambda_handler"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "ruby3.2"
  source_code_hash = data.archive_file.this.output_base64sha256
  timeout          = 30
}

resource "aws_lambda_permission" "event_bridge_lambda_execution" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssm_params_trigger.arn
  statement_id  = "AllowExecutionFromEventBridge"
}

# -----------------------------------------------------------------------------
# CloudWatch event trigger
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "ssm_params_trigger" {
  name        = "ssm_parameter_change"
  description = "Trigger for changes to SSM parameters with prefix /ec2_instance"

  event_pattern = <<EOF
{
  "source": [
    "aws.ssm"
  ],
  "detail-type": [
    "Parameter Store Change"
  ],
  "detail": {
    "operation": [
      "Create",
      "Update",
      "Delete"
    ],
    "name": [
      {
        "prefix": "/ec2_instance"
      }
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "ssm_params_trigger_to_lambda_function" {
  rule = aws_cloudwatch_event_rule.ssm_params_trigger.name
  arn  = aws_lambda_function.this.arn
}

# -----------------------------------------------------------------------------
# Lambda IAM Role and Policies
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

resource "aws_iam_role" "lambda" {
  name_prefix        = "lambda-"
  description        = "Allows Lambda function to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_policy" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_attached_policies" {
  for_each   = toset(var.policies_to_attach)
  role       = aws_iam_role.lambda.name
  policy_arn = each.key
}
