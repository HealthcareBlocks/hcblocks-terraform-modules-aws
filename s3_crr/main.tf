resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = var.source_bucket_name

  rule {
    id = "replicate-bucket"

    dynamic "filter" {
      for_each = var.replication_filter

      content {
        prefix = filter.value["filter"]
      }
    }

    status = "Enabled"

    destination {
      bucket        = var.destination_bucket_arn
      storage_class = try(var.destination_bucket_storage_class, null)

      encryption_configuration {
        replica_kms_key_id = var.destination_bucket_kms_id
      }
    }

    source_selection_criteria {
      dynamic "sse_kms_encrypted_objects" {
        for_each = length(var.destination_bucket_kms_id) > 1 ? [1] : []

        content {
          status = "Enabled"
        }
      }
    }
  }
}

resource "aws_iam_role" "replication" {
  name_prefix        = "bucket-replication-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [var.source_bucket_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${var.source_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${var.destination_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  name_prefix = "bucket-replication-"
  policy      = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}
