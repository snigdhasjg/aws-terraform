terraform {
  required_providers {
    aws = {
      version = "~> 5.15.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      component   = "aws-network"
      environment = "sandbox"
      owner       = var.owner
    }
  }
}
