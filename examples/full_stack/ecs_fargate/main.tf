data "aws_region" "current" {}

terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

# created and validated outside of Terraform
data "aws_acm_certificate" "test" {
  domain = "REPLACE-WITH-DOMAIN"
}

module "vpc" {
  source                            = "../../../vpc"
  cidr_block                        = "10.100.0.0/16"
  vpc_name                          = "vpc-prod"
  vpc_endpoint_interfaces_to_enable = ["ecr.api", "ecr.dkr", "logs", "secretsmanager"]
}

module "log_bucket" {
  source                            = "../../../s3_bucket"
  bucket_prefix                     = "logs"
  enable_load_balancer_log_delivery = true
  force_destroy                     = true # set to false in production environments
}

module "alb" {
  source                     = "../../../alb"
  acm_certificate            = data.aws_acm_certificate.test.arn
  enable_deletion_protection = false # set to true in production environments
  logs_bucket                = module.log_bucket.bucket_name
  subnets                    = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.id

  listeners = {
    https = {
      forward = {
        target_group_key = "containers"
      }
    }
  }

  target_groups = {
    containers = {
      name_prefix = "tg-"
      target_type = "ip"
    }
  }

  target_group_members_ip = {
    default = {
      create_attachment = false
    }
  }
}

resource "aws_security_group" "app" {
  name_prefix = "app-"
  description = "App"
  vpc_id      = module.vpc.id

  ingress {
    description     = "Accept HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    description = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ecs_cluster" {
  source                     = "../../../ecs_fargate_cluster"
  name                       = "cluster"
  cloudwatch_logs_group_name = aws_cloudwatch_log_group.ecs.name

  tags = {
    environment = "test"
  }
}

module "ecs_service" {
  source          = "../../../ecs_fargate_service"
  name            = "app"
  ecs_cluster_id  = module.ecs_cluster.id
  security_groups = [aws_security_group.app.id]
  subnets         = module.vpc.private_subnet_ids

  cpu    = 1024
  memory = 2048

  container_definitions = [
    {
      name      = "nginx"
      image     = "securecodebox/unsafe-https"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = data.aws_region.current.name
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 443
        }
      ]
      secrets = [
        {
          name      = "API_TOKEN"
          valueFrom = aws_ssm_parameter.secret.name
        }
      ]
      volume = {
        name      = "local-storage"
        host_path = "/ecs/local-storage"
      }
    }
  ]

  load_balancer_config = {
    default = {
      container_name   = "nginx"
      target_group_arn = module.alb.target_groups["containers"].arn
    }
  }

  task_exec_ssm_params = [
    aws_ssm_parameter.secret.arn,
  ]

  tasks_iam_role_policies = {
    S3Policy = aws_iam_policy.log_bucket_access.arn,
  }
}

resource "aws_ssm_parameter" "secret" {
  name        = "/secrets/API_TOKEN"
  description = "Secret parameter used in ecs_fargate example"
  type        = "SecureString"
  value       = var.secret_token
}

resource "aws_cloudwatch_log_group" "ecs" {
  name_prefix = "ecs-"
}

resource "aws_iam_policy" "log_bucket_access" {
  name        = "s3-log-bucket-access"
  description = "Log bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "S3:GetObject",
        ]
        Effect   = "Allow"
        Resource = "${module.log_bucket.bucket_arn}/*"
      },
    ]
  })
}

output "ecs_cluster_arn" {
  value = module.ecs_cluster.arn
}
