# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "log_group_name" {
  description = "The name of the log group. "
  type        = string
}

# -----------------------------------------------------------------------------
# SET ONE OR MORE OF THE FOLLOWING TARGET GROUP MEMBERS
# -----------------------------------------------------------------------------

variable "create_kms_key_and_policy" {
  description = "Set to `true` if you'd like this module to create a unique KMS key and associated usage policy. Conflicts with kms_key_id. If set to false after a key was initially created, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "Set to ARN of an KMS key to encrypt log data. Allows you to share a KMS key among multiple log groups. Conflicts with create_kms_key_and_policy. If the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group. All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested."
  type        = string
  default     = null
}

variable "log_group_class" {
  type        = string
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS. Cannot be changed without recreating log group. Be aware of the differences in supported features: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CloudWatch_Logs_Log_Classes.html."
  default     = "STANDARD"
}

variable "retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 365
}
