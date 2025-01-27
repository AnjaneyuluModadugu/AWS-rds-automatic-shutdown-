terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
# Configuration options
# Provide the AWS public and private keys of an service account or root account
    region = "ap-southeast-2"
}