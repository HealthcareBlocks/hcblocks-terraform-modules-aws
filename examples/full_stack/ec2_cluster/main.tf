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

locals {
  ami_name  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner = "099720109477"
}

module "vpc" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.1.0"
  cidr_block = "10.100.0.0/16"
  vpc_name   = "vpc-prod"
}

module "instance_web_1" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.1"

  ami_name                      = local.ami_name
  ami_owners                    = [local.ami_owner]
  delete_volumes_on_termination = true # this should be set to false in prod environments
  identifier                    = "web-1"
  instance_type                 = "t3.micro"
  subnet_id                     = module.vpc.private_subnet_ids[0]
  vpc_id                        = module.vpc.id

  sns_topic_high_cpu                = module.sns.topic_arn
  sns_topic_high_memory             = module.sns.topic_arn
  sns_topic_root_volume_low_storage = module.sns.topic_arn
  sns_topic_status_check_failed     = module.sns.topic_arn

  security_group_rules = {
    allow_443_vpc = {
      from_port   = 443
      to_port     = 443
      cidr_blocks = [module.vpc.cidr_block]
    }
  }
}

module "instance_web_2" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.1"

  ami_name                      = local.ami_name
  ami_owners                    = [local.ami_owner]
  delete_volumes_on_termination = true # this should be set to false in prod environments
  identifier                    = "web-2"
  instance_type                 = "t3.micro"
  subnet_id                     = module.vpc.private_subnet_ids[1]
  vpc_id                        = module.vpc.id

  sns_topic_high_cpu                = module.sns.topic_arn
  sns_topic_high_memory             = module.sns.topic_arn
  sns_topic_root_volume_low_storage = module.sns.topic_arn
  sns_topic_status_check_failed     = module.sns.topic_arn

  security_group_rules = {
    allow_443_vpc = {
      from_port   = 443
      to_port     = 443
      cidr_blocks = [module.vpc.cidr_block]
    }
  }
}

module "log_bucket" {
  source                            = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=s3_bucket/v1.1.0"
  bucket_prefix                     = "logs"
  enable_load_balancer_log_delivery = true
  force_destroy                     = true # set to false in production environments
}

module "alb" {
  source                     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=alb/v1.0.0"
  acm_certificate            = data.aws_acm_certificate.test.arn
  enable_deletion_protection = false # set to true in production environments
  logs_bucket                = module.log_bucket.bucket_name
  subnets                    = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.id

  listeners = {
    https = {
      forward = {
        target_group_key = "instances"
      }
    }
  }

  target_groups = {
    instances = {
      name_prefix = "tg-"
    }
  }

  target_group_members_instance = {
    instance_1 = {
      target_group_key = "instances"
      target_id        = module.instance_web_1.instance_id
    }

    instance_2 = {
      target_group_key = "instances"
      target_id        = module.instance_web_2.instance_id
    }
  }
}

module "sns" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.0.0"
  topic_name = "ec2-instance-alarms"
}
