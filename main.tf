provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name                 = "${var.project_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_s3_bucket" "main_bucket" {
  bucket        = "${var.project_name}-bucket"
  force_destroy = "true"
  tags          = var.tags
}

resource "aws_sns_topic" "main_topic" {
  name = "${var.project_name}-topic"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.main_topic.arn
  protocol  = "email"
  endpoint  = var.subscription_email
}