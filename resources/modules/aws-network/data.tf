data "aws_availability_zones" "az" {
  state = "available"
}

data "aws_region" "current" {}