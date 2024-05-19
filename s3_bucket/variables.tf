# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "bucket_prefix" {
  description = "First part of bucket name. Module automatically appends account id and region to name."
  type        = string

  validation {
    condition     = length(var.bucket_prefix) < 36
    error_message = "The bucket_prefix must be no longer than 35 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*$", var.bucket_prefix))
    error_message = "The bucket_prefix can only consist of lowercase letters, numbers, dots (.), and hyphens (-)."
  }

  validation {
    condition     = !can(regex("\\.\\.", var.bucket_prefix))
    error_message = "The bucket_prefix must not contain two adjacent periods."
  }

  validation {
    condition     = !can(regex("^(\\d{1,3}\\.){3}\\d{1,3}.*$", var.bucket_prefix))
    error_message = "The bucket_prefix must not be formatted as an IP address."
  }

  validation {
    condition     = !can(regex("^xn--", var.bucket_prefix))
    error_message = "The bucket_prefix must not start with the prefix xn--."
  }

  validation {
    condition     = !can(regex("^sthree(-|$)", var.bucket_prefix))
    error_message = "The bucket_prefix must not start with the prefix sthree- or sthree-configurator."
  }
}


# -----------------------------------------------------------------------------
# DEFAULT PUBLIC BLOCK PARAMETERS
# -----------------------------------------------------------------------------

variable "block_public_acls" {
  description = "See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block#block_public_acls"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block#block_public_policy"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block#ignore_public_acls"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block#restrict_public_buckets"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# OTHER DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "access_logs_bucket" {
  description = "Name of S3 bucket used to store access logs. Leave blank for none."
  type        = string
  default     = ""
}

variable "bucket_policy_additional_rights_json" {
  description = "The default policy for this bucket denies non-HTTPS requests. To include additional policy statements, set this variable in JSON format."
  type        = string
  default     = ""
}

variable "cors_rules" {
  description = "List of CORS rules. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration."
  type = list(object({
    allowed_headers = optional(set(string)),
    allowed_methods = set(string),
    allowed_origins = set(string),
    expose_headers  = optional(set(string)),
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "enable_load_balancer_log_delivery" {
  description = "Whether this bucket will receive logs from AWS load balancers. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html."
  type        = bool
  default     = false
}

variable "enable_log_delivery" {
  description = "Whether this bucket will receive access logs from AWS"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allows for all objects (including any locked objects) to be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  type        = bool
  default     = false
}

variable "log_storage_partition_date_source" {
  description = "Specifies the partition date source for the partitioned prefix. Valid values: EventTime, DeliveryTime."
  type        = string
  default     = "EventTime"
}

variable "log_storage_prefix" {
  description = "The prefix used in the access logs bucket for storing the logs of the bucket managed by this module."
  type        = string
  default     = "s3_access_logs/"
}

variable "sse_kms_key_id" {
  description = "AWS KMS master key ID used for the SSE-KMS encryption. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms"
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value tags for this bucket."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Whether to enable versioning. Enabled by default."
  type        = bool
  default     = true
}
