data "aws_vpc" "this" {
  id = var.vpc-id
}

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

data "aws_security_group" "default" {
  vpc_id = var.vpc-id
  name   = "default"
}

data "aws_ami" "amz_linux" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^ubuntu/images/hvm-ssd/ubuntu-focal-20\\.04-amd64-server-\\d+"

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

data "aws_iam_policy" "ssm_managed_policy" {
  name = "AmazonSSMManagedInstanceCore"
}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  my-public-cidr = "${chomp(data.http.my-public-ip.body)}/32"
}