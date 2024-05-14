# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "filename" {
  description = "Source file including extension of Lambda function"
  type        = string
}

variable "function_name" {
  description = "Name of Lambda function"
  type        = string
}

variable "function_handler" {
  description = "Lambda function handler"
  type        = string
}

variable "runtime" {
  type        = string
  description = "Runtime to use. See https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html."
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "additional_iam_policies" {
  description = "Additional IAM policies to attach to Lambda IAM role"
  type        = list(any)
  default     = []
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are x86_64 and arm64"
  type        = list(string)
  default     = ["x86_64"]
}

variable "description" {
  description = "Optional description of Lambda function"
  type        = string
  default     = ""
}

variable "env_variables" {
  description = "A map of environment variables used by the Lambda function."
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = " List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda function. See https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html."
  type        = list(string)
  default     = null
}

variable "memory_size" {
  description = "Maximum amount of memory in MB used by the Lambda function at runtime."
  type        = number
  default     = 128
}

variable "publish_new_version" {
  description = "Whether to publish creation/change as new Lambda function version."
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "VPC security groups used by function"
  type        = list(any)
  default     = []
}

variable "subnet_ids" {
  description = "VPC subnets to run function inside"
  type        = list(any)
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Key-value tags for this Lambda function."
  default     = {}
}

variable "timeout" {
  description = "Maximum amount of time in seconds allowed for Lambda function execution"
  type        = number
  default     = 3
}

variable "tracing_mode" {
  description = "Tracing mode of the Lambda function. Valid value can be either PassThrough or Active."
  type        = string
  default     = null
}
