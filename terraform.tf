terraform {
  cloud {
    organization = "cbecerrae"
    workspaces {
      name = "terraform-talana-infrastructure"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }
  }

  required_version = ">= 1.10.5"
}

