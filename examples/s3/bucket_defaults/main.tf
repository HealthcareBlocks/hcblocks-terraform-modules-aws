terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

# bucket used for storing S3 access logs
module "logs_bucket" {
  source              = "../../../s3_bucket"
  bucket_prefix       = "logs"
  enable_log_delivery = true
}

# example of standard bucket plus access logging and tags
module "bucket_with_defaults" {
  source             = "../../../s3_bucket"
  bucket_prefix      = "bucket-with-defaults"
  access_logs_bucket = module.logs_bucket.bucket_name

  tags = {
    environment = "test"
  }
}
