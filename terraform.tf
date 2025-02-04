terraform {
  backend "s3" {
    bucket         = "terraform-talana-automation-terraform-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-talana-automation-terraform-state-locks"
  }
  /*
  cloud {
    organization = "cbecerrae"
    workspaces {
      name = "terraform-talana-infrastructure"
    }
  }
  */
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }
  }

  required_version = ">= 1.10.5"
}
