# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "cidr_block" {
  description = "CIDR range. See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#VPC_Sizing."
  type        = string
}

variable "vpc_name" {
  description = "Descriptive name for the VPC"
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "availability_zone_count" {
  description = "Number of availability zones to use in this VPC and its subnets."
  type        = number
  default     = 2
}

variable "flow_log_config" {
  description = "Configuration of flow log(s) for this VPC."
  type        = map(any)
  default = {
    cw_logs_destination_enabled = true
    s3_destination_enabled      = false
    s3_bucket_arn               = null
  }
}

variable "private_subnets_enabled" {
  description = "Creates private subnets within this VPC. Per AWS Well-Architected Framework SEC05-BP01, create network layers by using private subnets for resources that do not receive direct inbound network traffic from public sources."
  type        = bool
  default     = true
}

variable "vpc_endpoint_gateways_to_enable" {
  description = "Creates VPC endpoint gateways in private subnets for supported AWS services. See https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html."
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_interfaces_to_enable" {
  description = "Creates VPC endpoint interfaces in private subnets for supported AWS services. Use service names listed on https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html. Additional costs are involved. See https://aws.amazon.com/privatelink/pricing/."
  type        = list(string)
  default     = []
}

variable "vpc_tenancy" {
  description = "Tenancy of instances launched in this VPC. Additional costs apply for dedicated tenancy."
  type        = string
  default     = "default"
}
