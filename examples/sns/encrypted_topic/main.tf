terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

module "sns_default_sse_encryption" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.0.0"

  kms_master_key_id = "alias/aws/sns"
  topic_name        = "security-alerts"
}

module "sns_custom_kms_encryption" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.0.0"

  kms_master_key_id = aws_kms_key.sns.arn
  topic_name        = "user-alerts"
}

resource "aws_kms_key" "sns" {
  description             = "sns-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "sns" {
  key_id = aws_kms_key.sns.id
  policy = jsonencode({
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key User (SNS Service Principal)"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
    ]
    Version = "2012-10-17"
  })
}
