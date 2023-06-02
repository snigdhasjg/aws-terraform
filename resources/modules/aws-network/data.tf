data "aws_availability_zones" "az" {
  state = "available"
}

data "aws_region" "current" {}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}