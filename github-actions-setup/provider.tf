terraform {
  required_providers {
    aws = {
      version = "~> 5.31.0"
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