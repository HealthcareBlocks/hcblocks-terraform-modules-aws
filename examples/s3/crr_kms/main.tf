terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

module "source_bucket" {
  source         = "../../../s3_bucket"
  bucket_prefix  = "source-bucket"
  sse_kms_key_id = aws_kms_key.key_a.id
}

module "destination_bucket" {
  providers = {
    aws = aws.us-east-2
  }

  source        = "../../../s3_bucket"
  bucket_prefix = "destination-bucket"
}

module "replication_example" {
  source                    = "../../../s3_crr"
  source_bucket_arn         = module.source_bucket.bucket_arn
  source_bucket_name        = module.source_bucket.bucket_id
  destination_bucket_arn    = module.destination_bucket.bucket_arn
  destination_bucket_kms_id = aws_kms_key.key_b.arn
}

resource "aws_kms_key" "key_a" {
  description             = "key_a"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "key_b" {
  provider                = aws.us-east-2
  description             = "key_b"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
