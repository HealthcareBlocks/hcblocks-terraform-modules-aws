# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "name" {
  description = "ECS cluster name."
  type        = string
}

variable "cloudwatch_logs_group_name" {
  description = "The name of the CloudWatch log group to send logs to."
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Key-value tags for this bucket."
  type        = map(string)
  default     = {}
}
