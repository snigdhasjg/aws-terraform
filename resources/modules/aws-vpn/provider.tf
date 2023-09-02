terraform {
  required_providers {
    aws = {
      version = "~> 4.53.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      component   = "aws-vpn"
      environment = "sandbox"
      owner       = var.owner
    }
  }
}
