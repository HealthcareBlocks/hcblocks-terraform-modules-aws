# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# -----------------------------------------------------------------------------

variable "acm_certificate" {
  description = "ARN of ACM SSL certificate"
  type        = string
}

variable "logs_bucket" {
  description = "Name of bucket used for storing ALB logs."
  type        = string
}

variable "target_groups" {
  description = "Map of target group configurations to create"
  type        = map(any)
}

variable "vpc_id" {
  description = "VPC associated with this ALB used for creating security group and non-lambda target groups."
  type        = string
}

# -----------------------------------------------------------------------------
# SET ONE OR MORE OF THE FOLLOWING TARGET GROUP MEMBERS
# -----------------------------------------------------------------------------

variable "target_group_members_instance" {
  description = "Map of instances to attach to a target group. Use `target_group_key` to attach to the target group created in `target_groups`. Set `target_id` to an instance ID. Optionally set `port`."
  type        = map(any)
  default     = {}
}

variable "target_group_members_ip" {
  description = "Map of IP targets to attach to a target group. Use `target_group_key` to attach to the target group created in `target_groups`. Set `target_id` to an IP address. `create_attachment` can be set to false for ECS services. Optionally set `port`."
  type        = map(any)
  default     = {}
}

variable "target_group_members_lambda" {
  description = "Map of lambda functions to attach to a target group. Use `target_group_key` to attach to the target group created in `target_groups`. Set `target_id` to lambda function's ARN. Set `lambda_function_name` to lambda function's name."
  type        = map(any)
  default     = {}
}

# -----------------------------------------------------------------------------
# DEFAULT PARAMETERS
# -----------------------------------------------------------------------------

variable "additional_security_groups" {
  description = "Additional security group IDs to associated with this ALB."
  type        = list(string)
  default     = []
}

variable "alb_http_port" {
  type        = number
  description = "HTTP port handled by the ALB. Based on AWS security best practices, ALB will redirect requests to this port to the HTTPS port,"
  default     = 80
}

variable "alb_https_port" {
  type        = number
  description = "HTTPS port handled by the ALB."
  default     = 443
}

variable "client_keep_alive" {
  description = "Client keep alive value in seconds. The valid range is 60-604800 seconds."
  type        = number
  default     = 3600
}

variable "connection_logs_enabled" {
  description = "Enables connection logs. Turned off by default; see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-connection-logs.html"
  type        = bool
  default     = false
}

variable "default_port" {
  description = "Default port used by listeners and target groups. For HIPAA-compliant applications, AWS requires end-to-end encryption, and this should be set to a port that handles HTTPS, e.g. 443"
  type        = number
  default     = 443
}

variable "default_protocol" {
  description = "Default protocol used by listeners and target group."
  type        = string
  default     = "HTTPS"
}

variable "desync_mitigation_mode" {
  description = "How the load balancer handles requests that might pose a security risk to an application due to HTTP desync. Valid values are monitor, defensive (default), strictest."
  type        = string
  default     = "defensive"
}

variable "drop_invalid_header_fields" {
  description = "Whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false)."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
  type        = bool
  default     = true
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "Whether the two headers (x-amzn-tls-version and x-amzn-tls-cipher-suite), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. "
  type        = bool
  default     = false
}

variable "enable_xff_client_port" {
  description = "Whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer."
  type        = bool
  default     = false
}

variable "healthcheck_healthy_threshold" {
  type        = number
  description = " Number of consecutive health check successes required before considering a target healthy. The range is 2-10."
  default     = 2
}

variable "healthcheck_unhealthy_threshold" {
  type        = number
  description = "Number of consecutive health check failures required before considering a target unhealthy. The range is 2-10."
  default     = 2
}

variable "healthcheck_interval" {
  type        = number
  description = "Approximate amount of time, in seconds, between health checks of an individual target. The range is 5-300."
  default     = 30
}

variable "healthcheck_path" {
  type        = string
  description = "Path in the backend service checked by ALB during health checks."
  default     = "/"
}

variable "healthcheck_passing_statuses" {
  type        = string
  description = "HTTP status codes that represent successful healthchecks in the backend service."
  default     = "200" # other codes that might be returned depending on path being queried: 301,302,401,403
}

variable "healthcheck_port" {
  type        = number
  description = "The port the load balancer uses when performing health checks on targets. Valid values are either traffic-port, to use the same port as the target group, or a valid port number between 1 and 65536. "
  default     = 443
}

variable "healthcheck_protocol" {
  type        = string
  description = "Protocol the load balancer uses when performing health checks on targets, HTTP or HTTPS."
  default     = "HTTPS"
}

variable "healthcheck_timeout" {
  type        = number
  description = "Amount of time, in seconds, during which no response from a target means a failed health check. The range is 2–120 seconds."
  default     = 10
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 60
}

variable "ingress_http_cidr_blocks" {
  type        = list(string)
  description = "IP addresses to allow for HTTP ingress"
  default     = ["0.0.0.0/0"]
}

variable "ingress_https_cidr_blocks" {
  type        = list(string)
  description = "IP addresses to allow for HTTPS ingress"
  default     = ["0.0.0.0/0"]
}

variable "internal" {
  description = "Whether this is an internal ALB."
  type        = bool
  default     = false
}

variable "listeners" {
  description = "Map of listener configurations to create"
  type        = any
  default     = {}
}

variable "logs_prefix" {
  description = "S3 bucket prefix"
  type        = string
  default     = "alb"
}

variable "name_prefix" {
  description = "First part of ALB name."
  type        = string
  default     = "alb-"
}

variable "preserve_host_header" {
  description = "Whether to preserve the Host header in the HTTP request and send it to the target without any change."
  type        = bool
  default     = false
}

variable "ssl_policy" {
  type        = string
  description = "Name of the SSL Policy for the listener. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies."
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs to attach to the LB."
}

variable "subnet_mapping" {
  description = "A list of subnet mapping blocks describing subnets to attach to load balancer."
  type        = list(map(string))
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Key-value tags for this ALB."
  default     = {}
}

variable "xff_header_processing_mode" {
  description = "Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are append (default), preserve, and remove."
  type        = string
  default     = "append"
}
