# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "roles_to_attach" {
  description = "Default roles to attach to the Lambda function's IAM role. This variable exposes the ability to use less permission policies."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ]
}
