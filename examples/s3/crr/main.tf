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
  source        = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.0.0"
  bucket_prefix = "source-bucket"
}

module "destination_bucket" {
  providers = {
    aws = aws.us-east-2
  }

  source        = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.0.0"
  bucket_prefix = "destination-bucket"
}

module "replication_example" {
  source                 = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_crr/v1.0.0"
  source_bucket_arn      = module.source_bucket.bucket_arn
  source_bucket_name     = module.source_bucket.bucket_id
  destination_bucket_arn = module.destination_bucket.bucket_arn
}
