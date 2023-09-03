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
      component   = "aws-openvpn"
      environment = "sandbox"
      owner       = var.owner
    }
  }
}
