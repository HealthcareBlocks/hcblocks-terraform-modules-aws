data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  kms_key_id        = var.create_kms_key_and_policy == true ? aws_kms_key.this[0].arn : var.kms_key_id
  log_group_class   = var.log_group_class
  retention_in_days = var.retention_in_days
}

# -----------------------------------------------------------------------------
# Region-specific KMS key for encrypting log group if a key is provided
# -----------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  count               = var.create_kms_key_and_policy == true ? 1 : 0
  description         = "Key for ${var.log_group_name} CloudWatch log group"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "Allow CloudWatch Logs to use key"
    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
    actions = [
      "kms:Decrypt*",
      "kms:Describe*",
      "kms:Encrypt*",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}"]
    }
  }
}
