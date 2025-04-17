terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

module "sns" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.1.0"

  topic_name = "system-alerts"

  subscriptions = {
    #email = {
    #  protocol = "email"
    #  endpoint = "REPLACE-WITH-EMAIL-ADDRESS"
    #}

    sqs = {
      protocol = "sqs"
      endpoint = aws_sqs_queue.encrypted_queue.arn
    }
  }
}

resource "aws_sqs_queue" "encrypted_queue" {
  name                    = "encrypted-queue"
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "encrypted_queue_receive_from_sns_topic" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.encrypted_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.sns.topic_arn]
    }
  }
}

resource "aws_sqs_queue_policy" "encrypted_queue" {
  queue_url = aws_sqs_queue.encrypted_queue.id
  policy    = data.aws_iam_policy_document.encrypted_queue_receive_from_sns_topic.json
}
