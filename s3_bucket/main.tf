data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  current_region = data.aws_region.current.name
  bucket_name    = format("%s-%s-%s", var.bucket_prefix, data.aws_caller_identity.current.account_id, local.current_region)

  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
  elb_service_accounts = {
    af-south-1     = "098369216593"
    ap-east-1      = "754344448648"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-northeast-3 = "383597477331"
    ap-south-1     = "718504428378"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-southeast-3 = "589379963580"
    ca-central-1   = "985666609251"
    cn-north-1     = "638102146993"
    cn-northwest-1 = "037604701340"
    eu-central-1   = "054676820928"
    eu-north-1     = "897822967062"
    eu-south-1     = "635631232127"
    eu-west-1      = "156460612806"
    eu-west-2      = "652711504416"
    eu-west-3      = "009996457667"
    me-south-1     = "076674570225"
    sa-east-1      = "507241528517"
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-gov-east-1  = "190560391635"
    us-gov-west-1  = "048591011584"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
  }
}

resource "aws_s3_bucket" "this_bucket" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_logging" "this_bucket" {
  count         = length(var.access_logs_bucket) > 0 ? 1 : 0
  bucket        = aws_s3_bucket.this_bucket.id
  target_bucket = var.access_logs_bucket
  target_prefix = var.log_storage_prefix

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = var.log_storage_partition_date_source
    }
  }
}

resource "aws_s3_bucket_versioning" "this_bucket" {
  count  = var.versioning_enabled == true ? 1 : 0
  bucket = aws_s3_bucket.this_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this_bucket" {
  bucket = aws_s3_bucket.this_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.sse_kms_key_id
    }

    bucket_key_enabled = var.sse_kms_key_id != null ? true : false
  }
}

data "aws_iam_policy_document" "this_bucket_policy" {
  statement {
    sid     = "DenyNonsecureRequests"
    actions = ["s3:*"]
    effect  = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.this_bucket.arn,
      "${aws_s3_bucket.this_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_log_delivery ? [1] : []

    content {
      sid     = "AllowAWSLogDelivery"
      actions = ["s3:PutObject"]
      effect  = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      resources = [
        aws_s3_bucket.this_bucket.arn,
        "${aws_s3_bucket.this_bucket.arn}/*"
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_load_balancer_log_delivery ? [1] : []

    content {
      sid     = "AllowAWSLBLogDeliveryNewerRegions"
      actions = ["s3:PutObject"]
      effect  = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }

      resources = [
        "${aws_s3_bucket.this_bucket.arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enable_load_balancer_log_delivery ? [1] : []

    content {
      sid     = "AllowAWSLBLogDeliveryOlderRegions"
      actions = ["s3:PutObject"]
      effect  = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.elb_service_accounts[local.current_region]}:root"]
      }

      resources = [
        "${aws_s3_bucket.this_bucket.arn}/*"
      ]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.this_bucket_policy.json,
    var.bucket_policy_additional_rights_json
  ]
}

resource "aws_s3_bucket_policy" "this_bucket_policy" {
  bucket = aws_s3_bucket.this_bucket.id
  policy = data.aws_iam_policy_document.combined.json
}

resource "aws_s3_bucket_public_access_block" "this_bucket" {
  bucket                  = aws_s3_bucket.this_bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  depends_on = [
    aws_s3_bucket_policy.this_bucket_policy,
  ]
}

resource "aws_s3_bucket_cors_configuration" "this_bucket" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this_bucket.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = try(cors_rule.value.allowed_headers, null)
      allowed_methods = try(cors_rule.value.allowed_methods, null)
      allowed_origins = try(cors_rule.value.allowed_origins, null)
      expose_headers  = try(cors_rule.value.expose_headers, null)
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
    }
  }
}
