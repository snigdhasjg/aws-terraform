data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_region" "this" {}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}