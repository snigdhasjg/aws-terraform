data "aws_subnets" "public-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "tag:connectivity"
    values = [
      "public"
    ]
  }
}

data "aws_vpc" "this" {
  id = var.vpc-id
}

data "aws_security_group" "default" {
  vpc_id = var.vpc-id
  name   = "default"
}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}