data "aws_partition" "current" {}

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  client_keep_alive                           = var.client_keep_alive
  desync_mitigation_mode                      = var.desync_mitigation_mode
  drop_invalid_header_fields                  = var.drop_invalid_header_fields
  enable_deletion_protection                  = var.enable_deletion_protection
  enable_tls_version_and_cipher_suite_headers = var.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                      = var.enable_xff_client_port
  idle_timeout                                = var.idle_timeout
  internal                                    = var.internal
  load_balancer_type                          = "application"
  name_prefix                                 = var.name_prefix
  preserve_host_header                        = var.preserve_host_header
  security_groups                             = concat([aws_security_group.default.id], var.additional_security_groups)

  # access logs required per HIPAA
  access_logs {
    enabled = true
    bucket  = var.logs_bucket
    prefix  = var.logs_prefix
  }

  # disabled by default
  connection_logs {
    enabled = var.connection_logs_enabled
    bucket  = var.logs_bucket
    prefix  = var.logs_prefix
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping

    content {
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      subnet_id            = subnet_mapping.value.subnet_id
    }
  }

  subnets                    = var.subnets
  tags                       = var.tags
  xff_header_processing_mode = var.xff_header_processing_mode
}

resource "aws_security_group" "default" {
  name_prefix = var.name_prefix
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = var.alb_http_port
    to_port     = var.alb_http_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_http_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = var.alb_https_port
    to_port     = var.alb_https_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_https_cidr_blocks
  }

  egress {
    description = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Listeners
# -----------------------------------------------------------------------------

# redirect HTTP to HTTPS per AWS security best practices
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = tostring(var.alb_https_port)
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "this" {
  for_each = { for k, v in var.listeners : k => v }

  certificate_arn = var.acm_certificate

  dynamic "default_action" {
    for_each = try([each.value.fixed_response], [])

    content {
      fixed_response {
        content_type = default_action.value.content_type
        message_body = try(default_action.value.message_body, null)
        status_code  = try(default_action.value.status_code, null)
      }

      order = try(default_action.value.order, null)
      type  = "fixed-response"
    }
  }

  dynamic "default_action" {
    for_each = try([each.value.forward], [])

    content {
      order            = try(default_action.value.order, null)
      target_group_arn = length(try(default_action.value.target_groups, [])) > 0 ? null : try(default_action.value.arn, aws_lb_target_group.this[default_action.value.target_group_key].arn, null)
      type             = "forward"
    }
  }

  dynamic "default_action" {
    for_each = try([each.value.weighted_forward], [])

    content {
      forward {
        dynamic "target_group" {
          for_each = try(default_action.value.target_groups, [])

          content {
            arn    = try(target_group.value.arn, aws_lb_target_group.this[target_group.value.target_group_key].arn, null)
            weight = try(target_group.value.weight, null)
          }
        }

        dynamic "stickiness" {
          for_each = try([default_action.value.stickiness], [])

          content {
            duration = try(stickiness.value.duration, 60)
            enabled  = try(stickiness.value.enabled, null)
          }
        }
      }

      order = try(default_action.value.order, null)
      type  = "forward"
    }
  }

  dynamic "default_action" {
    for_each = try([each.value.redirect], [])

    content {
      order = try(default_action.value.order, null)

      redirect {
        host        = try(default_action.value.host, null)
        path        = try(default_action.value.path, null)
        port        = try(default_action.value.port, null)
        protocol    = try(default_action.value.protocol, null)
        query       = try(default_action.value.query, null)
        status_code = default_action.value.status_code
      }

      type = "redirect"
    }
  }

  load_balancer_arn = aws_lb.this.arn
  port              = try(each.value.port, var.default_port)
  protocol          = try(each.value.protocol, var.default_protocol)
  ssl_policy        = var.ssl_policy
}

# -----------------------------------------------------------------------------
# Listener Rules
# -----------------------------------------------------------------------------

locals {
  # This allows rules to be specified under the listener definition
  listener_rules = flatten([
    for listener_key, listener_values in var.listeners : [
      for rule_key, rule_values in lookup(listener_values, "rules", {}) :
      merge(rule_values, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    ]
  ])
}

resource "aws_lb_listener_rule" "this" {
  for_each = { for v in local.listener_rules : "${v.listener_key}/${v.rule_key}" => v }

  listener_arn = try(each.value.listener_arn, aws_lb_listener.this[each.value.listener_key].arn)
  priority     = try(each.value.priority, null)

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "redirect"]

    content {
      type  = "redirect"
      order = try(action.value.order, null)

      redirect {
        host        = try(action.value.host, null)
        path        = try(action.value.path, null)
        port        = try(action.value.port, null)
        protocol    = try(action.value.protocol, null)
        query       = try(action.value.query, null)
        status_code = action.value.status_code
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "fixed-response"]

    content {
      type  = "fixed-response"
      order = try(action.value.order, null)

      fixed_response {
        content_type = action.value.content_type
        message_body = try(action.value.message_body, null)
        status_code  = try(action.value.status_code, null)
      }
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "forward"]

    content {
      type             = "forward"
      order            = try(action.value.order, null)
      target_group_arn = try(action.value.target_group_arn, aws_lb_target_group.this[action.value.target_group_key].arn, null)
    }
  }

  dynamic "action" {
    for_each = [for action in each.value.actions : action if action.type == "weighted-forward"]

    content {
      type  = "forward"
      order = try(action.value.order, null)

      forward {
        dynamic "target_group" {
          for_each = try(action.value.target_groups, [])

          content {
            arn    = try(target_group.value.arn, aws_lb_target_group.this[target_group.value.target_group_key].arn)
            weight = try(target_group.value.weight, null)
          }
        }

        dynamic "stickiness" {
          for_each = try([action.value.stickiness], [])

          content {
            enabled  = try(stickiness.value.enabled, null)
            duration = try(stickiness.value.duration, 60)
          }
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "host_header")]

    content {
      dynamic "host_header" {
        for_each = try([condition.value.host_header], [])

        content {
          values = host_header.value.values
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "http_header")]

    content {
      dynamic "http_header" {
        for_each = try([condition.value.http_header], [])

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "http_request_method")]

    content {
      dynamic "http_request_method" {
        for_each = try([condition.value.http_request_method], [])

        content {
          values = http_request_method.value.values
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "path_pattern")]

    content {
      dynamic "path_pattern" {
        for_each = try([condition.value.path_pattern], [])

        content {
          values = path_pattern.value.values
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "query_string")]

    content {
      dynamic "query_string" {
        for_each = try([condition.value.query_string], [])

        content {
          key   = try(query_string.value.key, null)
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in each.value.conditions : condition if contains(keys(condition), "source_ip")]

    content {
      dynamic "source_ip" {
        for_each = try([condition.value.source_ip], [])

        content {
          values = source_ip.value.values
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Certificate(s)
# -----------------------------------------------------------------------------

locals {
  # Take the list of `additional_certificate_arns` from the listener and create
  # a map entry that maps each certificate to the listener key. This map of maps
  # is then used to create the certificate resources.
  additional_certs = merge(values({
    for listener_key, listener_values in var.listeners : listener_key =>
    {
      # This will cause certs to be detached and reattached if certificate_arns
      # towards the front of the list are updated/removed. However, we need to have
      # unique keys on the resulting map and we can't have computed values (i.e. cert ARN)
      # in the key so we are using the array index as part of the key.
      for idx, cert_arn in lookup(listener_values, "additional_certificate_arns", []) :
      "${listener_key}/${idx}" => {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    } if length(lookup(listener_values, "additional_certificate_arns", [])) > 0
  })...)
}

resource "aws_lb_listener_certificate" "this" {
  for_each = { for k, v in local.additional_certs : k => v }

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

# -----------------------------------------------------------------------------
# Target groups
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  for_each = { for k, v in var.target_groups : k => v }

  deregistration_delay = try(each.value.deregistration_delay, 300)

  dynamic "health_check" {
    for_each = try([each.value.health_check], [])

    content {
      enabled             = try(health_check.value.enabled, true)
      healthy_threshold   = try(health_check.value.healthy_threshold, var.healthcheck_healthy_threshold)
      interval            = try(health_check.value.interval, var.healthcheck_interval)
      matcher             = try(health_check.value.matcher, var.healthcheck_passing_statuses)
      path                = try(health_check.value.path, var.healthcheck_path)
      port                = try(health_check.value.port, var.healthcheck_port)
      protocol            = try(health_check.value.protocol, var.healthcheck_protocol)
      timeout             = try(health_check.value.timeout, var.healthcheck_timeout)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, var.healthcheck_unhealthy_threshold)
    }
  }

  lambda_multi_value_headers_enabled = try(each.value.lambda_multi_value_headers_enabled, null)
  load_balancing_algorithm_type      = try(each.value.load_balancing_algorithm_type, null)
  load_balancing_anomaly_mitigation  = try(each.value.load_balancing_anomaly_mitigation, null)
  load_balancing_cross_zone_enabled  = try(each.value.load_balancing_cross_zone_enabled, null)
  name                               = try(each.value.name, null)
  name_prefix                        = try(each.value.name_prefix, null)
  port                               = try(each.value.target_type, null) == "lambda" ? null : try(each.value.port, var.default_port)
  preserve_client_ip                 = try(each.value.preserve_client_ip, null)
  protocol                           = try(each.value.target_type, null) == "lambda" ? null : try(each.value.protocol, var.default_protocol)
  protocol_version                   = try(each.value.protocol_version, null)
  slow_start                         = try(each.value.slow_start, 0)

  dynamic "stickiness" {
    for_each = try([each.value.stickiness], [])

    content {
      cookie_duration = try(stickiness.value.cookie_duration, null)
      cookie_name     = try(stickiness.value.cookie_name, null)
      enabled         = try(stickiness.value.enabled, true)
      type            = try(stickiness.value.type, null)
    }
  }

  target_type = try(each.value.target_type, "instance")
  vpc_id      = try(each.value.vpc_id, var.vpc_id)

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Target group attachments
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "instances" {
  for_each = { for k, v in var.target_group_members_instance : k => v if lookup(v, "create_attachment", true) }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = try(each.value.port, var.default_port)
  availability_zone = try(each.value.availability_zone, null)
}

resource "aws_lb_target_group_attachment" "ip_targets" {
  for_each = { for k, v in var.target_group_members_ip : k => v if lookup(v, "create_attachment", true) }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = try(each.value.port, var.default_port)
  availability_zone = try(each.value.availability_zone, null)
}

resource "aws_lb_target_group_attachment" "lambda_functions" {
  for_each = { for k, v in var.target_group_members_lambda : k => v if lookup(v, "create_attachment", true) }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  availability_zone = try(each.value.availability_zone, null)

  depends_on = [aws_lambda_permission.this]
}

# -----------------------------------------------------------------------------
# Lambda Permissions
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "this" {
  for_each = { for k, v in var.target_group_members_lambda : k => v }

  function_name = each.value.lambda_function_name
  qualifier     = try(each.value.lambda_qualifier, null)

  statement_id       = try(each.value.lambda_statement_id, "AllowExecutionFromLb")
  action             = try(each.value.lambda_action, "lambda:InvokeFunction")
  principal          = try(each.value.lambda_principal, "elasticloadbalancing.${data.aws_partition.current.dns_suffix}")
  source_arn         = aws_lb_target_group.this[each.value.target_group_key].arn
  source_account     = try(each.value.lambda_source_account, null)
  event_source_token = try(each.value.lambda_event_source_token, null)
}
