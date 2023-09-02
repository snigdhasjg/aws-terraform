resource "aws_security_group" "ec2_sg" {
  name        = "${var.tag_prefix}-ec2-sg"
  description = "Allow ec2 instance to talk to others"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic within itself"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  egress {
    description = "Allow all external traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_prefix}-ec2-sg"
  }
}

resource "aws_security_group_rule" "windows_rdp_rule" {
  count             = var.ami_type == "WINDOWS_SERVER_2019" ? 1 : 0
  description       = "Allow RDP TCP traffic from ${var.tag_prefix} public IP"
  security_group_id = aws_security_group.ec2_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_blocks       = [local.my-public-cidr]
}

resource "aws_security_group_rule" "linux_ssh_rule" {
  count             = var.ami_type == "AMAZON_LINUX_2" ? 1 : 0
  description       = "Allow SSH TCP traffic from ${var.tag_prefix} public IP"
  security_group_id = aws_security_group.ec2_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [local.my-public-cidr]
}

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key_file" {
  filename        = "${path.module}/key/ec2-private-key.pem"
  content         = tls_private_key.rsa_key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.tag_prefix}-windows-ec2"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

resource "aws_iam_role" "ec2_service_role" {
  name = "${var.tag_prefix}-ec2-service-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    policy = data.aws_iam_policy_document.ec2_role_policy.json
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.tag_prefix}-windows-ec2-instance-profile"
  role = aws_iam_role.ec2_service_role.name
}

resource "aws_instance" "this" {
  ami                                  = local.ami_id[var.ami_type]
  instance_type                        = var.instance_type
  key_name                             = aws_key_pair.ec2_key.key_name
  subnet_id                            = data.aws_subnets.public-subnets.ids[0]
  instance_initiated_shutdown_behavior = "terminate"
  iam_instance_profile                 = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address          = true
  get_password_data                    = true

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  tags = {
    Name = "${var.tag_prefix}-ec2"
  }
}