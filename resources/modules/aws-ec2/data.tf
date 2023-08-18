data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "public-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:connectivity"
    values = [
      "public"
    ]
  }
}

data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  name   = "default"
}

data "aws_ami" "windows_server_2019" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^.*WindowsServer2019-V2.*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "ena-support"
    values = [true]
  }
}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  my-public-cidr = "${chomp(data.http.my-public-ip.body)}/32"
}