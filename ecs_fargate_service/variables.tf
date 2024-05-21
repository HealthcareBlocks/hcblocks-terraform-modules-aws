# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "container_definitions" {
  description = "List of container definitions to run as an ECS service. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html."
  type        = any
}

variable "name" {
  description = "Service name."
  type        = string
}

variable "ecs_cluster_id" {
  description = "ARN of an ECS cluster."
  type        = string
}

variable "load_balancer_config" {
  description = "Configuration block for load balancers. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/register-multiple-targetgroups.html."
  type        = any
}

variable "security_groups" {
  description = "VPC security groups associated with the service."
  type        = any
}

variable "subnets" {
  description = "VPC subnets associated with the service. These should be private subnets per the AWS Well-Architected Framework."
  type        = any
}

# -----------------------------------------------------------------------------
# IAM PERMISSIONS
# -----------------------------------------------------------------------------

variable "task_exec_ssm_params" {
  description = "ARN's of SSM Paramaters that are allowed to be read during task execution"
  type        = list(string)
  default     = []
}

variable "task_exec_secrets" {
  description = "ARN's of Secrets that are allowed to be read during task execution"
  type        = list(string)
  default     = []
}

variable "task_exec_kms_keys" {
  description = "ARN's of KMS keys that are allowed to be read during task execution"
  type        = list(string)
  default     = []
}

variable "tasks_iam_role_policies" {
  description = "IAM policies that grant access for the service containers to make calls to other AWS services."
  type        = any
  default     = {}
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "alarm_names" {
  description = "One or more CloudWatch alarm names"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP address."
  type        = bool
  default     = false
}

variable "cpu" {
  description = "Number of cpu units used by the task."
  type        = number
  default     = 1024
}

variable "cpu_architecture" {
  description = "CPU architecture to use."
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running."
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  type        = bool
  default     = true
}

variable "enable_alarm_rollback" {
  description = "Determines whether to configure Amazon ECS to roll back the service if a service deployment fails. If rollback is used, when a service deployment fails, the service is rolled back to the last deployment that completed successfully."
  type        = bool
  default     = false
}

variable "ephemeral_storage_size_in_gib" {
  description = "The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount. Accepted values: 21 - 200"
  type        = number
  default     = 50
}

variable "fargate_platform_version" {
  description = "ECS Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "force_new_deployment" {
  description = "Enable to force a new task deployment of the service."
  type        = bool
  default     = false
}

variable "lb_default_container_port" {
  description = "Port on the container to associate with the load balancer."
  type        = number
  default     = 443
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task."
  type        = number
  default     = 2048
}

variable "operating_system_family" {
  description = "Operating system used by container"
  type        = string
  default     = "LINUX"
}

variable "proxy_configuration" {
  description = "Configuration block for the App Mesh proxy"
  type        = any
  default     = {}
}

variable "service_connect_configuration" {
  description = "The ECS Service Connect configuration for this service to discover and connect to services, and be discovered by, and connected from, other services within a namespace"
  type        = any
  default     = {}
}

variable "service_registries" {
  description = "Service discovery registries for the service"
  type        = any
  default     = {}
}

variable "task_family" {
  description = "A unique name for your task"
  type        = string
  default     = "service"
}

variable "volume" {
  description = "Configuration block for volumes that containers in your task may use"
  type        = any
  default     = {}
}
