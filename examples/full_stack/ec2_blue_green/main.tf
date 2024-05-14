terraform {
  required_version = "~> 1.8"
}

provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source     = "../../../vpc"
  cidr_block = "10.100.0.0/16"
  vpc_name   = "vpc-prod"
}

resource "aws_security_group" "web-app" {
  name_prefix = "web-app-"
  description = "Web App"
  vpc_id      = module.vpc.id

  ingress {
    description = "Accept HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.cidr_block]
  }

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

resource "aws_instance" "web-1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web-app.id]
}

resource "aws_instance" "web-2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.web-app.id]
}

module "log_bucket" {
  source                            = "../../../s3_bucket"
  bucket_prefix                     = "logs"
  enable_load_balancer_log_delivery = true
  force_destroy                     = true # set to false in production environments
}

# created and validated outside of Terraform
data "aws_acm_certificate" "test" {
  domain = "REPLACE-WITH-DOMAIN"
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
      weighted_forward = {
        target_groups = [
          {
            target_group_key = "blue"
            weight           = 100
          },
          {
            target_group_key = "green"
            weight           = 0
          }
        ]
      }
    }
  }

  target_groups = {
    blue = {
      name_prefix = "blue-"
    }

    green = {
      name_prefix = "green-"
    }
  }

  target_group_members_instance = {
    blue_instance = {
      target_group_key = "blue"
      target_id        = aws_instance.web-1.id
    }

    green_instance = {
      target_group_key = "green"
      target_id        = aws_instance.web-2.id
    }
  }
}
