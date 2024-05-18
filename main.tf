data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  zone_names = sort(data.aws_availability_zones.available.names)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = var.vpc_tenancy

  tags = {
    Name = var.vpc_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "Internet Gateway | ${var.vpc_name} VPC"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# NAT Gateways (if private subnets are enabled)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.private_subnets_enabled == true ? var.availability_zone_count : 0
  domain = "vpc"
}

# Hourly fee applies to NAT gateways. See https://aws.amazon.com/vpc/pricing/.
resource "aws_nat_gateway" "this" {
  count         = var.private_subnets_enabled == true ? var.availability_zone_count : 0
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = {
    Name = "NAT Gateway ${count.index + 1} | ${var.vpc_name} VPC"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count                   = var.availability_zone_count
  availability_zone       = local.zone_names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.this.id

  tags = {
    Name = "Public Subnet | ${local.zone_names[count.index]} | ${var.vpc_name} VPC"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  count                   = var.private_subnets_enabled == true ? var.availability_zone_count : 0
  availability_zone       = local.zone_names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 8, 100 + count.index)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id

  tags = {
    Name = "Private Subnet | ${local.zone_names[count.index]} | ${var.vpc_name} VPC"
    Type = "Private"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Default route
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "Public Route Table | ${var.vpc_name} VPC"
    Type = "Public"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Private Routes
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "Private Route Table | ${var.vpc_name} VPC"
    Type = "Private"
  }
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(aws_nat_gateway.this)
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
}

# ---------------------------------------------------------------------------------------------------------------------
# Route Table Association with Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table_association" "rta_public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_default_route_table.default.id
}

resource "aws_route_table_association" "rta_private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = element(aws_route_table.private[*].id, count.index)
}

# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch Log Group for VPC Logs
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/vpc/${aws_vpc.this.id}"
  log_group_class   = "STANDARD"
  retention_in_days = 365
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC Flow Log
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "flow_logs_publisher_assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_logs_publisher" {
  name_prefix        = "vpc-flow-logs-role-"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_publisher_assume_role_policy.json
}

data "aws_iam_policy_document" "flow_logs_publish_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_publish_policy" {
  name_prefix = "vpc-flow-logs-policy-"
  role        = aws_iam_role.flow_logs_publisher.id
  policy      = data.aws_iam_policy_document.flow_logs_publish_policy.json
}

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  iam_role_arn    = aws_iam_role.flow_logs_publisher.arn
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
}

# [CIS 4.3] Ensure the default security group of every VPC restricts all traffic
# [EC2.2] The VPC default security group should not allow inbound and outbound traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Creating VPC endpoints for various AWS services to keep traffic private per AWS security best practices
# Also satisfies [EC2.10] Amazon EC2 should be configured to use VPC endpoints
# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoint" {
  count = length(var.vpc_endpoint_interfaces_to_enable) > 0 ? 1 : 0

  name        = "VPC-Endpoint"
  description = "Rules for VPC endpoint traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Additional fees apply. See https://aws.amazon.com/privatelink/pricing/.
resource "aws_vpc_endpoint" "interfaces" {
  for_each = toset(var.vpc_endpoint_interfaces_to_enable)

  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.this.id

  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint[0].id,
  ]

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${each.key} interface"
  }
}

# AWS does not charge for gateway endpoints.
resource "aws_vpc_endpoint" "gateways" {
  for_each = toset(var.vpc_endpoint_gateways_to_enable)

  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.this.id
  route_table_ids   = flatten([aws_route_table.private[*].id])

  tags = {
    Name = "${each.key} gateway"
  }
}
