data "aws_ami" "this" {
  most_recent = var.ami_use_most_recent
  owners      = var.ami_owners

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_virtualization_type]
  }
}

resource "aws_instance" "this" {
  lifecycle {
    ignore_changes = [
      ami,               # <- we don't want an updated AMI to automatically replace this instance
      root_block_device, # <- changes to EBS volumes can occur outside of this module
      user_data,         # <- we only want user data to be applicable during the initial boot
    ]
  }

  ami                         = data.aws_ami.this.id
  associate_public_ip_address = var.associate_public_ip_address
  disable_api_termination     = var.termination_protection_enabled
  iam_instance_profile        = aws_iam_instance_profile.this.name
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = var.enhanced_monitoring
  subnet_id                   = var.subnet_id
  tenancy                     = var.tenancy

  user_data = <<-EOT
  #!/bin/bash
  if [ -f "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl" ]; then
    echo "CloudWatch agent is already installed."
  else
    if grep -q debian /etc/os-release; then
      wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/debian/${var.ami_architecture == "x86_64" ? "amd64" : "arm64"}/latest/amazon-cloudwatch-agent.deb
      dpkg -i -E ./amazon-cloudwatch-agent.deb
      rm -fr ./amazon-cloudwatch-agent.deb
    elif grep -q amazon /etc/os-release; then
      wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/${var.ami_architecture == "x86_64" ? "amd64" : "arm64"}/latest/amazon-cloudwatch-agent.rpm
      rpm -U ./amazon-cloudwatch-agent.rpm
      rm -fr ./amazon-cloudwatch-agent.rpm
    fi
  fi
  cat <<'EOF' > /cloudwatch-agent.json
  ${jsonencode(local.cw_agent_template)}
  EOF
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/cloudwatch-agent.json
  ${var.user_data}
  EOT

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = var.metadata_hop_limit
    http_tokens                 = var.metadata_token
    instance_metadata_tags      = var.metadata_instance_tags_enabled ? "enabled" : "disabled"
  }

  root_block_device {
    delete_on_termination = var.delete_volumes_on_termination
    encrypted             = true
    iops                  = var.root_volume_iops
    kms_key_id            = var.kms_key_id
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
  }

  tags                   = merge({ Name = var.identifier }, var.tags)
  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_groups_to_attach)
}

# -----------------------------------------------------------------------------
# IAM Role and Policies
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${var.identifier}-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.identifier}-"
  role        = aws_iam_role.this.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "additional_iam_policies" {
  for_each   = toset(var.additional_iam_policies_to_attach)
  role       = aws_iam_role.this.name
  policy_arn = each.key
}

# -----------------------------------------------------------------------------
# Security Group and rules
# -----------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name_prefix = "${var.identifier}-"
  description = var.identifier
  vpc_id      = var.vpc_id

  tags = {
    Name = var.identifier
  }
}

resource "aws_security_group_rule" "egress_all" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "ingress_rule" {
  for_each          = var.security_group_rules
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = try(each.value.protocol, "tcp")
  from_port         = each.value.from_port
  to_port           = each.value.to_port

  cidr_blocks              = try(each.value.cidr_blocks, null)
  self                     = try(each.value.self, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_actions       = [var.sns_topic_high_cpu]
  alarm_description   = format("CPU average >= %s%% for %s seconds on %s (%s)", var.cpu_alarm_threshold, var.cpu_alarm_period, aws_instance.this.id, aws_instance.this.private_ip)
  alarm_name          = format("High-CPU-%s", aws_instance.this.id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  ok_actions          = [var.sns_topic_high_cpu]
  period              = var.cpu_alarm_period
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_actions       = [var.sns_topic_high_memory]
  alarm_description   = format("Memory average >= %s%% for %s seconds on %s (%s)", var.memory_alarm_threshold, var.memory_alarm_period, aws_instance.this.id, aws_instance.this.private_ip)
  alarm_name          = format("High-Memory-%s", aws_instance.this.id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "System/Linux"
  ok_actions          = [var.sns_topic_high_memory]
  period              = var.memory_alarm_period
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_actions       = [var.sns_topic_status_check_failed]
  alarm_description   = format("Status check failed for %s seconds on %s (%s)", var.status_check_failed_alarm_period, aws_instance.this.id, aws_instance.this.private_ip)
  alarm_name          = format("Status-Check-Failed-%s", aws_instance.this.id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  ok_actions          = [var.sns_topic_status_check_failed]
  period              = var.status_check_failed_alarm_period
  statistic           = "Average"
  threshold           = 1
  unit                = "Count"

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "low_storage_space" {
  alarm_actions       = [var.sns_topic_root_volume_low_storage]
  alarm_description   = format("/ is %s%% full on %s (%s)", var.root_volume_alarm_threshold, aws_instance.this.id, aws_instance.this.private_ip)
  alarm_name          = format("Low-Storage-%s", aws_instance.this.id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "System/Linux"
  ok_actions          = [var.sns_topic_root_volume_low_storage]
  period              = var.root_volume_alarm_period
  statistic           = "Maximum"
  threshold           = var.root_volume_alarm_threshold
  unit                = "Percent"

  dimensions = {
    InstanceId = aws_instance.this.id
    fstype     = var.root_volume_fstype
    path       = "/"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Agent Template
# -----------------------------------------------------------------------------

locals {
  cw_agent_template = {
    agent = {
      metrics_collection_interval = 60
      logfile                     = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
    }

    metrics = {
      namespace = "System/Linux"
      metrics_collected = {
        disk = {
          resources = [
            "*"
          ]
          measurement = [
            "used_percent"
          ]
          ignore_file_system_types    = var.cloudwatch_ignore_filesystems
          metrics_collection_interval = var.cloudwatch_metrics_collection_interval
          drop_device                 = true # Causes device to not be included as a dimension for disk metrics
        }

        mem = {
          measurement = [
            "mem_used_percent"
          ]
          metrics_collection_interval = var.cloudwatch_metrics_collection_interval
        }

        swap = {
          measurement = [
            "used_percent"
          ]
          metrics_collection_interval = var.cloudwatch_metrics_collection_interval
        }
      }

      append_dimensions = { InstanceId = "$${aws:InstanceId}" }

      force_flush_interval = 60
    }

    logs = {
      logs_collected = {
        files = {
          collect_list = concat([
            {
              file_path      = "/var/log/auth.log"
              log_group_name = "/var/log/secure"
              timezone       = "UTC"
              auto_removal   = false
            },
            {
              file_path      = "/var/log/secure"
              log_group_name = "/var/log/secure"
              timezone       = "UTC"
              auto_removal   = false
            },
            {
              file_path      = "/var/log/syslog"
              log_group_name = "/var/log/syslog"
              timezone       = "UTC"
              auto_removal   = false
            }
          ], var.cloudwatch_additional_logs_config)
        }
      }
      log_stream_name      = "{hostname}"
      force_flush_interval = 5
    }
  }
}
