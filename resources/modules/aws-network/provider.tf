terraform {
  required_providers {
    aws = {
      version = "~> 4.53.0"
    }
    http = {
      version = "~> 2.1.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      component   = "aws-network"
      environment = "sandbox"
      owner       = "Snigdhajyoti Ghosh"
    }
  }
}
