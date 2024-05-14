# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "source_bucket_arn" {
  description = "Replication source bucket. Must have versioning enabled."
  type        = string
}

variable "source_bucket_name" {
  description = "Replication source bucket name. Must have versioning enabled."
  type        = string
}

variable "destination_bucket_arn" {
  description = "Replication destination bucket. Must have versioning enabled."
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "destination_bucket_kms_id" {
  description = "Key ARN or Alias ARN of the customer managed AWS KMS key stored in AWS Key Management Service (KMS) for the destination bucket."
  type        = string
  default     = ""
}


variable "destination_bucket_storage_class" {
  description = "The storage class used to store the object. By default, Amazon S3 uses the storage class of the source object to create the object replica. See https://docs.aws.amazon.com/AmazonS3/latest/API/API_Destination.html#AmazonS3-Type-Destination-StorageClass."
  type        = string
  default     = null
}

variable "replication_filter" {
  description = "See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration#filter."
  type        = map(any)
  default     = {}
}
