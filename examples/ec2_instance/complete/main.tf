terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.1.0"
  cidr_block = "10.100.0.0/16"
  vpc_name   = "vpc-prod"
}

module "instance_frontend" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.0"

  ami_name                      = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-*"
  delete_volumes_on_termination = true # this should be set to false in prod environments
  identifier                    = "frontend"
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

  tags = {
    environment = "test"
  }
}

module "instance_amazonlinux" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.0"

  ami_name                      = "al2023-ami-2023.4*"
  delete_volumes_on_termination = true # this should be set to false in prod environments
  identifier                    = "api"
  instance_type                 = "t3.micro"
  root_volume_fstype            = "xfs" # used by one of the CloudWatch alarms
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

module "instance_arm64" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.0"

  ami_name                      = "al2023-ami-2023.4*"
  ami_architecture              = "arm64" # important to set for arm64 instances
  delete_volumes_on_termination = true    # this should be set to false in prod environments
  identifier                    = "arm64"
  instance_type                 = "t4g.micro"
  root_volume_fstype            = "xfs" # used by one of the CloudWatch alarms
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

module "sns" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.0.0"
  topic_name = "ec2-instance-alarms"
}
