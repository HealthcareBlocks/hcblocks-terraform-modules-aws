terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

locals {
  # alternately use the Terraform AWS aws_key_pair resource
  tswift_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 tswift-work",

    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4lDakvjqOYvZtOZIUafS9BT6rL8ooBEvWGt3pe0nu0 tswift-home",
  ]

  tkelce_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGj0gzO8KT9cR93BJb+1fRcru7A68Fh6e0/K+BwnrmH1 tkelce",
  ]
}

module "ec2_instance_user_manager" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance_user_manager/v1.1.0"
}

module "ec2_instance_user_tswift" {
  source       = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance_user/v1.0.0"
  instance_ids = [module.instance_bastion.instance_id]
  username     = "tswift"
  groups       = ["sshusers", "admin"] # these groups should already exist on the instance
  ssh_keys     = local.tswift_keys
  sudoer       = true

  # this is important since the below module contains automations
  # that need to be in place before managing the first user
  depends_on = [module.ec2_instance_user_manager]
}

module "ec2_instance_user_tkelce" {
  source       = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance_user/v1.0.0"
  instance_ids = [module.instance_bastion.instance_id]
  username     = "tkelce"
  groups       = ["sshusers"] # these groups should already exist on the instance
  ssh_keys     = local.tkelce_keys
  sudoer       = false

  depends_on = [module.ec2_instance_user_manager]
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

module "vpc" {
  source                  = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=vpc/v1.1.0"
  cidr_block              = "10.10.0.0/16"
  private_subnets_enabled = false
  vpc_name                = "vpc-test"
}

# -----------------------------------------------------------------------------
# EC2 Instance and related resources
# -----------------------------------------------------------------------------

module "instance_bastion" {
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance/v1.0.2"

  ami_name                      = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owners                    = ["099720109477"]
  delete_volumes_on_termination = true # this should be set to false in prod environments
  identifier                    = "bastion"
  instance_type                 = "t3.micro"
  subnet_id                     = module.vpc.public_subnet_ids[0]
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

    /*
    allow_ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["MY-IP-ADDRESS"]
    }
    */
  }

  user_data = <<-EOF
    #!/bin/bash
    groupadd sshusers
    echo "AllowGroups sshusers" >> /etc/ssh/sshd_config
    systemctl restart sshd
    EOF
}

module "sns" {
  source     = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=sns/v1.0.0"
  topic_name = "ec2-instance-alarms"
}
