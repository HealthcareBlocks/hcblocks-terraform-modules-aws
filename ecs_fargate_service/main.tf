data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

resource "aws_ecs_service" "this" {
  cluster                = var.ecs_cluster_id
  desired_count          = var.desired_count
  enable_execute_command = var.enable_execute_command
  force_new_deployment   = var.force_new_deployment
  launch_type            = "FARGATE"
  name                   = var.name
  platform_version       = var.fargate_platform_version
  task_definition        = aws_ecs_task_definition.this.arn
  tags                   = var.tags

  dynamic "alarms" {
    for_each = length(var.alarm_names) > 0 ? [var.alarm_names] : []

    content {
      enable      = true
      rollback    = var.enable_alarm_rollback
      alarm_names = var.alarm_names
    }
  }

  dynamic "load_balancer" {
    for_each = { for k, v in var.load_balancer_config : k => v }

    content {
      container_name   = load_balancer.value.container_name
      container_port   = try(load_balancer.value.container_port, var.lb_default_container_port)
      target_group_arn = load_balancer.value.target_group_arn
    }
  }

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "service_connect_configuration" {
    for_each = length(var.service_connect_configuration) > 0 ? [var.service_connect_configuration] : []

    content {
      enabled = try(service_connect_configuration.value.enabled, true)

      dynamic "log_configuration" {
        for_each = try([service_connect_configuration.value.log_configuration], [])

        content {
          log_driver = try(log_configuration.value.log_driver, null)
          options    = try(log_configuration.value.options, null)

          dynamic "secret_option" {
            for_each = try(log_configuration.value.secret_option, [])

            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }

      namespace = lookup(service_connect_configuration.value, "namespace", null)

      dynamic "service" {
        for_each = try([service_connect_configuration.value.service], [])

        content {

          dynamic "client_alias" {
            for_each = try([service.value.client_alias], [])

            content {
              dns_name = try(client_alias.value.dns_name, null)
              port     = client_alias.value.port
            }
          }

          discovery_name        = try(service.value.discovery_name, null)
          ingress_port_override = try(service.value.ingress_port_override, null)
          port_name             = service.value.port_name
        }
      }
    }
  }

  dynamic "service_registries" {
    for_each = length(var.service_registries) > 0 ? [{ for k, v in var.service_registries : k => v }] : []

    content {
      container_name = try(service_registries.value.container_name, null)
      container_port = try(service_registries.value.container_port, null)
      port           = try(service_registries.value.port, null)
      registry_arn   = service_registries.value.registry_arn
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  container_definitions    = jsonencode(var.container_definitions)
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.task_exec.arn
  task_role_arn      = aws_iam_role.tasks.arn

  cpu          = var.cpu
  memory       = var.memory
  network_mode = "awsvpc"

  ephemeral_storage {
    size_in_gib = var.ephemeral_storage_size_in_gib
  }

  dynamic "proxy_configuration" {
    for_each = length(var.proxy_configuration) > 0 ? [var.proxy_configuration] : []

    content {
      container_name = proxy_configuration.value.container_name
      properties     = try(proxy_configuration.value.properties, null)
      type           = try(proxy_configuration.value.type, null)
    }
  }

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  dynamic "volume" {
    for_each = var.volume

    content {
      host_path = try(volume.value.host_path, null)
      name      = try(volume.value.name, volume.key)

      dynamic "efs_volume_configuration" {
        for_each = try([volume.value.efs_volume_configuration], [])

        content {
          dynamic "authorization_config" {
            for_each = try([efs_volume_configuration.value.authorization_config], [])

            content {
              access_point_id = try(authorization_config.value.access_point_id, null)
              iam             = try(authorization_config.value.iam, null)
            }
          }

          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = try(efs_volume_configuration.value.root_directory, null)
          transit_encryption      = try(efs_volume_configuration.value.transit_encryption, null)
          transit_encryption_port = try(efs_volume_configuration.value.transit_encryption_port, null)
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "task_exec_assume" {
  statement {
    sid     = "ECSTaskExecutionAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  name_prefix        = "ecs-task-exec-"
  description        = "Task execution role"
  assume_role_policy = data.aws_iam_policy_document.task_exec_assume.json
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role_policy_attachment" "task_exec_role_policy" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_exec" {
  dynamic "statement" {
    for_each = length(var.task_exec_ssm_params) > 0 ? [1] : []

    content {
      actions   = ["ssm:GetParameters"]
      resources = var.task_exec_ssm_params
    }
  }

  dynamic "statement" {
    for_each = length(var.task_exec_secrets) > 0 ? [1] : []

    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.task_exec_secrets
    }
  }

  dynamic "statement" {
    for_each = length(var.task_exec_kms_keys) > 0 ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      resources = var.task_exec_kms_keys
    }
  }
}

locals {
  create_task_exec_policy = length(var.task_exec_ssm_params) > 0 || length(var.task_exec_secrets) > 0 || length(var.task_exec_kms_keys) > 0
}

resource "aws_iam_policy" "task_exec" {
  count       = local.create_task_exec_policy ? 1 : 0
  name_prefix = "task-exec-policy-"
  description = "Task execution role IAM policy"
  policy      = data.aws_iam_policy_document.task_exec.json
}

resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  count      = local.create_task_exec_policy ? 1 : 0
  role       = aws_iam_role.task_exec.name
  policy_arn = aws_iam_policy.task_exec[0].arn
}

data "aws_iam_policy_document" "tasks_assume" {
  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.partition}:ecs:${local.region}:${local.account_id}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "tasks" {
  name_prefix        = "ecs-task-"
  description        = "Task role"
  assume_role_policy = data.aws_iam_policy_document.tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "tasks" {
  for_each = { for k, v in var.tasks_iam_role_policies : k => v }

  role       = aws_iam_role.tasks.name
  policy_arn = each.value
}
