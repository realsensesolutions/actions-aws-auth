terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

terraform {
  backend "s3" {
    region = "us-east-1"
  }
}

provider "aws" {
  # Default region for Cognito resources
  region = "us-east-1"
}
