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
      component   = "aws-s3"
      environment = "sandbox"
      owner       = "Snigdhajyoti Ghosh"
    }
  }
}
