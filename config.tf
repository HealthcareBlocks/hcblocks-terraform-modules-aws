terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.2"
    }
  }
}
