data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  ecr_name = format("%s-%s-%s", var.name_prefix, data.aws_caller_identity.current.account_id, data.aws_region.current.name)
}

resource "aws_ecr_repository" "this" {
  name                 = local.ecr_name
  image_tag_mutability = var.image_tag_mutability
  tags                 = var.tags

  encryption_configuration {
    encryption_type = var.kms_key_id != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_id
  }
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = var.scan_type

  rule {
    scan_frequency = var.scan_frequency

    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
