terraform {
  backend "s3" {
    region  = "ap-south-1"
    acl     = "bucket-owner-full-control"
    bucket  = "terraform-backend-joe-sandbox"
    encrypt = true
    key     = "aws-terraform/resources/terraform.tfstate"
  }
}