# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "First part of repository name. Module automatically appends account id and region to name."
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE."
  type        = string
  default     = "MUTABLE"
}

variable "kms_key_id" {
  description = "AWS KMS master key ID used for encryption. If not specified, uses the default AWS managed key for ECR."
  type        = string
  default     = null
}

variable "scan_frequency" {
  description = "The frequency that scans are performed at for a private registry. Can be SCAN_ON_PUSH, CONTINUOUS_SCAN, or MANUAL."
  type        = string
  default     = "CONTINUOUS_SCAN"
}

variable "scan_type" {
  description = "The scanning type to set for the registry. Can be either ENHANCED or BASIC."
  type        = string
  default     = "ENHANCED"
}

variable "tags" {
  description = "Key-value tags for this repo."
  type        = map(string)
  default     = {}
}
