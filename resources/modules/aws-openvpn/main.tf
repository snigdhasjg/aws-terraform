resource "aws_security_group" "openvpn_ec2_sg" {
  name        = "openvpn-ec2-sg"
  description = "Allow openvpn ec2 instance to talk to others"
  vpc_id      = var.vpc-id

  ingress {
    description = "Allow OpenVPN UDP traffic from Joe public IP"
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = [local.my-public-cidr]
  }

  ingress {
    description = "Allow OpenVPN TCP traffic from Joe public IP"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [local.my-public-cidr]
  }

  ingress {
    description = "Allow OpenVPN TCP traffic from Joe public IP"
    protocol    = "tcp"
    from_port   = 943
    to_port     = 943
    cidr_blocks = [local.my-public-cidr]
  }

  ingress {
    description = "Allow DNS TCP traffic from Joe public IP"
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [local.my-public-cidr]
  }

  ingress {
    description = "Allow DNS UDP traffic from Joe public IP"
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [local.my-public-cidr]
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
  filename        = "${path.module}/key/ec2-private-key.pem"
  content         = tls_private_key.rsa_key.private_key_pem
  file_permission = "0400"
}

resource "local_file" "client_open_vpn_config" {
  filename        = "${path.module}/key/client.ovpn"
  content         = <<-EOF
    client
    proto udp
    remote ${aws_instance.openvpn_ec2.public_dns} 1194
    dev tun
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    remote-cert-tls server

    # Use the same subnet as the server but choose a unique IP for the client
    # ifconfig 172.16.0.2 255.255.0.0

    # Set the client DNS server to the specified address
    dhcp-option DNS ${cidrhost(data.aws_vpc.this.cidr_block, 2)}

    # Use the auth-user-pass directive to prompt for username and password
    auth-user-pass

    # Uncomment the following line if you want to redirect all client internet traffic through the VPN.
    # redirect-gateway def1

    # Uncomment the following line to prevent DNS leaks when redirecting all client internet traffic through the VPN.
    # block-outside-dns

    # Uncomment the following line if you want to enable compression to save bandwidth (optional).
    # comp-lzo

    # Add any additional client-specific configurations here if needed.
    <ca>
    ${var.server-cert.ca_certificate}
    </ca>

  EOF
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

    apt install -y unzip openvpn openssl

    # Install AWS cli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -f awscliv2.zip
    rm -rf ./aws

    mkdir -p /etc/openvpn/config
    cd /etc/openvpn/config
    echo "${var.server-cert.certificate}" > server.crt
    echo "${var.server-cert.key}" > server.key
    echo "${var.server-cert.ca_certificate}" > ca.crt
    openssl dhparam -out /etc/openvpn/config/dh.pem 2048
    cp /etc/openvpn/server/ca.crt /usr/local/share/ca-certificates
    update-ca-certificates

    touch /etc/openvpn/config/vpn-users.sh
    chmod 777 /etc/openvpn/config/vpn-users.sh
    bash -c "cat > /etc/openvpn/config/vpn-users.sh << EOL
    #!/bin/sh

    ALLOWED_USER="user1"
    ALLOWED_PASS="password1"

    if [ "$username" = "$ALLOWED_USER" ] && [ "$password" = "$ALLOWED_PASS" ]; then
      exit 0
    fi
    exit 1
    EOL"

    bash -c "cat > /etc/openvpn/server.conf << EOL
    port 1194
    proto udp
    dev tun
    ca /etc/openvpn/config/ca.crt
    cert /etc/openvpn/config/server.crt
    key /etc/openvpn/config/server.key
    dh /etc/openvpn/config/dh.pem
    server 172.16.0.0 255.255.0.0
    plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn
    verify-client-cert none
    username-as-common-name
    client-cert-not-required
    auth-user-pass-verify /etc/openvpn/config/vpn-users.sh via-env
    script-security 3
    status /var/log/openvpn/status.log
    log /var/log/openvpn/server.log
    EOL"

    bash -c "cat > /etc/pam.d/openvpn << EOL
    auth    required pam_permit.so
    account required pam_permit.so
    EOL"

    ufw allow 1194/udp

    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    systemctl start openvpn@server
    systemctl enable openvpn@server
  EOF

  tags = {
    Name = "${var.tag_prefix}-openvpn-ec2"
  }
}

