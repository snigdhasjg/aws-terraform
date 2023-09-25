terraform {
  required_providers {
    aws = {
      version = "~> 5.15.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.10"
    }
  }
  backend "s3" {
    region  = "ap-south-1"
    acl     = "bucket-owner-full-control"
    bucket  = "terraform-backend-joe-sandbox"
    encrypt = true
    key     = "aws-terraform/tailscale/terraform.tfstate"
  }
}

provider "aws" {
  default_tags {
    tags = {
      component   = "tailscale"
      environment = "sandbox"
      owner       = "Snigdhajyoti Ghosh"
    }
  }
}

provider "tailscale" {
  user_agent = "terraform"
}
