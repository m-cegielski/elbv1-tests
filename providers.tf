terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.73"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  skip_region_validation      = var.aws_profile != "elb-tests"
  skip_credentials_validation = var.aws_profile != "elb-tests"
  skip_requesting_account_id  = var.aws_profile != "elb-tests"

  dynamic "endpoints" {
    for_each = var.aws_profile != "elb-tests" ? [1] : []

    content {
      ec2 = var.aws_endpoint
      sts = var.aws_endpoint
      elb = var.aws_endpoint
      acm = var.aws_endpoint
    }
  }
}
