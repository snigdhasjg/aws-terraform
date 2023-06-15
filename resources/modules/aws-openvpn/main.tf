resource "aws_security_group" "openvpn_ec2_sg" {
  name        = "openvpn-ec2-sg"
  description = "Allow openvpn ec2 instance to talk to others"
  vpc_id      = var.vpc-id

  ingress {
    description = "Allow OpenVPN UDP traffic from Joe public IP"
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["${chomp(data.http.my-public-ip.body)}/32"]
  }

  ingress {
    description = "Allow DNS TCP traffic from Joe public IP"
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["${chomp(data.http.my-public-ip.body)}/32"]
  }

  ingress {
    description = "Allow DNS UDP traffic from Joe public IP"
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["${chomp(data.http.my-public-ip.body)}/32"]
  }

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
    Name = "${var.tag_prefix}-openvpn-ec2-sg"
  }
}

resource "aws_security_group_rule" "openvpn_ec2_to_vpc_connection" {
  description              = "Allow all traffic from OpenVPN"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = data.aws_security_group.default.id
  source_security_group_id = aws_security_group.openvpn_ec2_sg.id
}

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key_file" {
  filename        = "ec2-private-key.pem"
  content         = tls_private_key.rsa_key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "openvpn_ec2_key" {
  key_name   = "${var.tag_prefix}-openvpn-ec2"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

resource "aws_iam_role" "openvpn_ec2_service_role" {
  name = "${var.tag_prefix}-openvpn-ec2-service-role"

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

  managed_policy_arns = [
    data.aws_iam_policy.ssm_managed_policy.arn
  ]
}

resource "aws_iam_instance_profile" "openvpn_ec2_profile" {
  name = "${var.tag_prefix}-openvpn-ec2-instance-profile"
  role = aws_iam_role.openvpn_ec2_service_role.name
}

# https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
resource "aws_instance" "openvpn_ec2" {
  ami                                  = data.aws_ami.amz_linux.id
  instance_type                        = "t2.micro"
  key_name                             = aws_key_pair.openvpn_ec2_key.key_name
  subnet_id                            = data.aws_subnets.public-subnets.ids[0]
  instance_initiated_shutdown_behavior = "terminate"
  iam_instance_profile                 = aws_iam_instance_profile.openvpn_ec2_profile.name
  associate_public_ip_address          = true

  vpc_security_group_ids = [
    aws_security_group.openvpn_ec2_sg.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y

    apt install -y unzip openvpn

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -f awscliv2.zip
    rm -rf ./aws

    cd /etc/openvpn/server
    echo "${var.server-cert.certificate}" > server.crt
    echo "${var.server-cert.key}" > server.key
    echo "${var.server-cert.ca_certificate}" > ca.crt
    openvpn --genkey --secret ta.key
    cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz .
    gunzip server.conf.gz
    cd -

    mkdir -p /etc/openvpn/client-custom-config
    cd /etc/openvpn/client-custom-config
    echo "${var.client-cert.certificate}" > client.crt
    echo "${var.client-cert.key}" > client.key
    echo "${var.client-cert.ca_certificate}" > ca.crt
    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf base.conf
    cp /etc/openvpn/server/ta.key .
    cd -


    cp /etc/openvpn/server/ca.crt /usr/local/share/ca-certificates
    update-ca-certificates

    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

  EOF

  tags = {
    Name = "${var.tag_prefix}-openvpn-ec2"
  }
}