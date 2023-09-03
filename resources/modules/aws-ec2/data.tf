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

data "aws_ami" "amz_linux" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^amzn2-ami-kernel-5.10-hvm-.*-x86_64.*"

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

data "aws_iam_policy_document" "ec2_role_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::twer-cross-account-bucket",
      "arn:aws:s3:::twer-cross-account-bucket/*"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::twer-cross-account-bucket/macabrEquinox/*",
      "arn:aws:s3:::twer-cross-account-bucket/generated/*",
    ]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]

    resources = [
      "arn:aws:kms:ap-south-1:121859831222:alias/twer-cross-account-bucket-key"
    ]
  }
}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  my-public-cidr = "${chomp(data.http.my-public-ip.body)}/32"
  ami_id         = {
    WINDOWS_SERVER_2019 = data.aws_ami.windows_server_2019.id
    AMAZON_LINUX_2      = data.aws_ami.amz_linux.id
  }
}