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
      component   = "github-actions"
      environment = "sandbox"
      owner       = "Snigdhajyoti Ghosh"
    }
  }
}

terraform {
  backend "s3" {
    acl     = "bucket-owner-full-control"
    bucket  = "terraform-backend-joe-sandbox"
    encrypt = true
    key     = "aws-terraform/setup/terraform.tfstate"
  }
}