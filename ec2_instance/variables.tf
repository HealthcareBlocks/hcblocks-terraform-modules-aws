# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "ami_name" {
  description = "Name of the AMI to use for this instance. Supports wildcard (*)."
  type        = string
}

variable "identifier" {
  description = "Name used in IAM role (if created by this module) and instance tags"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}


variable "sns_topic_high_cpu" {
  description = "Set to an SNS topic ARN to be notified when instance CPU levels are high. Also see `cpu_alarm_threshold` variable."
  type        = string
}

variable "sns_topic_high_memory" {
  description = "Set to an SNS topic ARN to be notified when instance memory usage levels are high. Also see `memory_alarm_threshold` variable."
  type        = string
}

variable "sns_topic_root_volume_low_storage" {
  description = "Set to an SNS topic ARN to be notified when root volume is almost full. Also see `root_volume_alarm_threshold` variable."
  type        = string
}

variable "sns_topic_status_check_failed" {
  description = "Set to an SNS topic ARN to be notified when instance status check fails."
  type        = string
}

variable "subnet_id" {
  description = "VPC subnet ID to use for this instance. AWS recommends using private subnets."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID associated with this instance."
  type        = string
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "additional_iam_policies_to_attach" {
  description = "Additional IAM policies to associate with this instance."
  type        = list(string)
  default     = []
}

variable "additional_security_groups_to_attach" {
  description = "This module creates a security group for the instance with a default egress rule. To set ingress rules, either set `additional_security_groups_to_attach` to a list of security group ID's or set the `security_group_rules` variable."
  type        = list(any)
  default     = []
}

variable "ami_architecture" {
  description = "OS architecture of the AMI, e.g. x86_64 or arm64"
  type        = string
  default     = "x86_64"
}

variable "ami_owners" {
  description = "List of AMI owners to limit search. Valid values: an AWS account ID, self (the current account), or an AWS owner alias (e.g., amazon, aws-marketplace, microsoft)."
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_use_most_recent" {
  description = "If more than one result is returned, use the most recent AMI."
  type        = bool
  default     = true
}

variable "ami_virtualization_type" {
  description = "Type of virtualization of the AMI (hvm or paravirtual)."
  type        = string
  default     = "hvm"
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with this instance. Defaults to false since AWS security best practices recommend launching instances in private VPC subnets."
  type        = bool
  default     = false
}

variable "cloudwatch_additional_logs_config" {
  description = "Additional logs to collect by the CloudWatch agent. Should contain a list of map objects containing the following fields: file_path, log_group_name, timezone, auto_removal. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html."
  type        = list(any)
  default     = []
}

variable "cloudwatch_ignore_filesystems" {
  description = "Filesystems to ignore by the CloudWatch agent."
  type        = list(string)
  default = [
    "devtmpfs",
    "nfs",
    "nfs4",
    "overlay",
    "squashfs",
    "sysfs",
    "tmpfs",
    "vfat"
  ]
}

variable "cloudwatch_metrics_collection_interval" {
  description = "The metrics collection interval (in seconds) by the CloudWatch agent."
  type        = number
  default     = 60
}

variable "cpu_alarm_period" {
  description = "Minimum period (in seconds) to trigger this alarm. Note that this alarm uses 1 evaluation period."
  type        = number
  default     = 300
}

variable "cpu_alarm_threshold" {
  description = "Percent utilization at which the instance's CloudWatch alert for high CPU usage is triggered."
  type        = number
  default     = 90
}

variable "enhanced_monitoring" {
  description = "Whether to enable detailed monitoring for this instance."
  type        = bool
  default     = true
}

variable "delete_volumes_on_termination" {
  description = "Whether the volume should be destroyed on instance termination. Defaults to false."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance which can be managed using the aws_key_pair resource."
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use when encrypting the volume. Must be configured to perform drift detection."
  type        = string
  default     = null
}

variable "memory_alarm_threshold" {
  description = "Percent utilization at which the instance's CloudWatch alert for high memory usage is triggered."
  type        = number
  default     = 90
}

variable "memory_alarm_period" {
  description = "Minimum period (in seconds) to trigger this alarm. Note that this alarm uses 1 evaluation period."
  type        = number
  default     = 300
}

variable "metadata_hop_limit" {
  description = "Desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Valid values are integer from 1 to 64. Default is set to 2 so that containers running on EC2 instances can access metadata."
  type        = number
  default     = 2
}

variable "metadata_instance_tags_enabled" {
  description = "Whether metadata responses include instance tags. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#work-with-tags-in-IMDS."
  type        = bool
  default     = false
}

variable "metadata_token" {
  description = "Whether tokens are required by the EC2 Instance Metadata Service. Set to 'optional' if not required."
  type        = string
  default     = "required"
}

variable "root_volume_alarm_threshold" {
  description = "Percent utilization at which the instance's CloudWatch alert for low disk space is triggered."
  type        = number
  default     = 85
}

variable "root_volume_alarm_period" {
  description = "Minimum period (in seconds) to trigger this alarm. Note that this alarm uses 1 evaluation period."
  type        = number
  default     = 300
}

variable "root_volume_fstype" {
  description = "File system type, e.g. ext4. This value is used by the CloudWatch alarm created by `sns_topic_root_volume_low_storage`."
  type        = string
  default     = "ext4"
}

variable "root_volume_iops" {
  description = "Amount of provisioned IOPS. Only valid for volume_type of io1, io2 or gp3."
  type        = number
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB. Defaults to the size specified in the AMI."
  type        = number
  default     = null
}

variable "root_volume_type" {
  description = "Type of volume. Valid values include standard, gp2, gp3 (default), io1, io2, sc1, or st1."
  type        = string
  default     = "gp3"
}

variable "security_group_rules" {
  description = <<EOF
    This module creates a security group for the instance with a default egress rule. To set ingress rules, either set the `security_group_rules` variable to a map of rules or set `additional_security_groups_to_attach` to a list of security group ID's.

    Example:

    security_group_rules = {
      allow_443_vpc = {
        from_port = 443
        to_port = 443
        cidr_blocks = [data.aws_vpc.prod.cidr_block]
      }

      allow_8080_from_frontend_sg = {
        from_port = 8080
        to_port = 8080
        source_security_group_id = aws_security_group.frontend.id
      }
    }
  EOF
  type        = map(any)
}

variable "status_check_failed_alarm_period" {
  description = "Minimum period (in seconds) to trigger this alarm. Note that this alarm uses 1 evaluation period."
  type        = number
  default     = 120
}

variable "tags" {
  description = "Optional map of key-value pairs to use as tags. Note that this module already sets a Name tag equivalent to the `identifier` variable."
  type        = map(any)
  default     = {}
}

variable "tenancy" {
  description = "Instance tenancy default, dedicated, or host. Additional costs may apply, see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/dedicated-instance.html."
  type        = string
  default     = "default"
}

variable "termination_protection_enabled" {
  description = "Whether to protect this instance against API-based termination. See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_ChangingDisableAPITermination.html."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional commands to run on first boot"
  default     = ""
}
