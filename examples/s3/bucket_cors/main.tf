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

# example of using cross-origin resource sharing (CORS)
module "bucket_with_cors" {
  source             = "../../../s3_bucket"
  bucket_prefix      = "bucket-with-cors"
  access_logs_bucket = module.logs_bucket.bucket_name

  cors_rules = [
    {
      allowed_headers = [
        "*",
      ]
      allowed_methods = [
        "GET",
      ]
      allowed_origins = [
        "https://example.com",
      ]
    },
    {
      allowed_headers = [
        "*",
      ]
      allowed_methods = [
        "POST",
      ]
      allowed_origins = [
        "https://test.co",
      ],
      expose_headers  = ["ETag"]
      max_age_seconds = 60
    }
  ]
}
