# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "topic_name" {
  description = "Name of SNS topic"
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "archive_policy" {
  description = "The message archive policy for FIFO topics. See https://docs.aws.amazon.com/sns/latest/dg/message-archiving-and-replay-topic-owner.html."
  type        = string
  default     = null
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO topics. See https://docs.aws.amazon.com/sns/latest/dg/fifo-message-dedup.html."
  type        = bool
  default     = false
}

variable "delivery_policy" {
  description = "The SNS delivery policy. See https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html."
  type        = string
  default     = null
}

variable "display_name" {
  description = "The display name for the topic."
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Boolean indicating whether or not to create a FIFO (first-in-first-out) topic."
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK."
  type        = string
  default     = null
}

variable "lambda_failure_feedback_role_arn" {
  description = "IAM role for failure feedback."
  type        = string
  default     = null
}

variable "lambda_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic."
  type        = string
  default     = null
}

variable "lambda_success_feedback_sample_rate" {
  description = "Percentage of success to sample."
  type        = number
  default     = null
}

variable "sqs_failure_feedback_role_arn" {
  description = "IAM role for failure feedback."
  type        = string
  default     = null
}

variable "sqs_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic."
  type        = string
  default     = null
}

variable "sqs_success_feedback_sample_rate" {
  description = "Percentage of success to sample."
  type        = number
  default     = null
}

variable "subscriptions" {
  description = "A map of subscriptions to create"
  type        = any
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Key-value tags for this ALB."
  default     = {}
}

variable "tracing_config" {
  description = "Tracing mode of an Amazon SNS topic. Valid values: PassThrough, Active."
  type        = string
  default     = null
}
