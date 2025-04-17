terraform {
  required_version = "~> 1.11"
}

provider "aws" {
  region = "us-west-2"
}

# bucket used for storing S3 access logs
module "logs_bucket" {
  source              = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.4.0"
  bucket_prefix       = "logs"
  enable_log_delivery = true
}

# example of using custom KMS key instead of AWS-SSE for encryption
module "bucket_with_custom_encryption_key" {
  source             = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.4.0"
  bucket_prefix      = "bucket-with-custom-key"
  access_logs_bucket = module.logs_bucket.bucket_name
  sse_kms_key_id     = aws_kms_key.s3_bucket.id
}

resource "aws_kms_key" "s3_bucket" {
  description             = "s3-bucket-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
