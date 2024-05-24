# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "cloudwatch_log_group" {
  description = "ARN of CloudWatch Log group used for capturing logs of this state machine."
  type        = string
}

variable "definition" {
  description = "The Amazon States Language definition of the state machine. See https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html."
  type        = string
}

variable "state_machine_name" {
  description = "Name of state machine"
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "additional_iam_policies" {
  description = "List of IAM policies to attach to the state machine IAM role"
  type        = list(string)
  default     = []
}

variable "allowed_lambda_functions_to_invoke" {
  description = "Lambda function ARNs that can be invoked by this state machine. Creates the proper IAM policy."
  type        = list(string)
  default     = []
}

variable "allowed_sqs_queues_to_call" {
  description = "SQS queue ARNs that can be called by this state machine. Creates the proper IAM policy."
  type        = list(string)
  default     = []
}

variable "enable_tracing_configuration" {
  description = "Determines whether AWS X-Ray tracing is on."
  type        = bool
  default     = true
}

variable "logs_include_execution_data" {
  description = "Determines whether execution data is included in CloudWatch logs."
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Defines which category of execution history events are logged. Valid values: ALL, ERROR, FATAL, OFF."
  type        = string
  default     = "ERROR"
}

variable "publish" {
  description = "Set to true to publish a version of the state machine during creation."
  type        = bool
  default     = false
}

variable "state_machine_type" {
  description = "Determines whether a Standard or Express state machine is created. You cannot update the type of a state machine once it has been created. Valid values: STANDARD, EXPRESS."
  type        = string
  default     = "STANDARD"
}

variable "tags" {
  type        = map(string)
  description = "Key-value tags for this ALB."
  default     = {}
}
