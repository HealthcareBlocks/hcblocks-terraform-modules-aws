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
  source = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance_user_manager/v1.0.0"
}

module "ec2_instance_user_tswift" {
  source       = "git::https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws.git?ref=ec2_instance_user/v1.0.0"
  instance_ids = [aws_instance.bastion.id]
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
  instance_ids = [aws_instance.bastion.id]
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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
    #!/bin/bash
    groupadd sshusers
    echo "AllowGroups sshusers" >> /etc/ssh/sshd_config
    systemctl restart sshd
    EOF
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-"
  description = "Bastion"
  vpc_id      = module.vpc.id

  /*
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["MY-IP-ADDRESS"]
  }
  */

  egress {
    description = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# -----------------------------------------------------------------------------
# IAM Role and Policies
# -----------------------------------------------------------------------------

resource "aws_iam_role" "bastion" {
  name_prefix           = "bastion-"
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Effect": "Allow",
			"Sid": ""
		}
	]
}
EOF
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "bastion-"
  role        = aws_iam_role.bastion.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
