resource "aws_acm_certificate" "server-cert" {
  private_key       = var.server-cert.key
  certificate_body  = var.server-cert.certificate
  certificate_chain = var.server-cert.ca_certificate
}

resource "aws_acm_certificate" "client-cert" {
  private_key       = var.client-cert.key
  certificate_body  = var.client-cert.certificate
  certificate_chain = var.client-cert.ca_certificate
}

resource "aws_cloudwatch_log_group" "vpn-log" {
  name              = "${var.tag_prefix}-vpn-log"
  retention_in_days = 3
}

resource "aws_security_group" "vpn_endpoint_sg" {
  name   = "vpn-endpoint-sg"
  vpc_id = var.vpc-id

  ingress {
    description = "Allow UDP traffic from Joe public IP"
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
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
    Name = "${var.tag_prefix}-vpn-endpoint-sg"
  }
}

resource "aws_security_group_rule" "vpn_endpoint_to_vpc_connection" {
  description              = "Allow all traffic from VPN"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = data.aws_security_group.default.id
  source_security_group_id = aws_security_group.vpn_endpoint_sg.id
}

resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  client_cidr_block      = var.vpn_cidr_block
  server_certificate_arn = aws_acm_certificate.server-cert.arn
  split_tunnel           = true
  self_service_portal    = "enabled"

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client-cert.arn
  }

  connection_log_options {
    enabled              = true
    cloudwatch_log_group = aws_cloudwatch_log_group.vpn-log.name
  }

  vpc_id             = var.vpc-id
  security_group_ids = [aws_security_group.vpn_endpoint_sg.id]
  vpn_port           = 1194

  tags = {
    Name = "${var.tag_prefix}-vpn"
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_endpoint_authorization_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_network_association" "vpn_endpoint_vpc_subnet_association" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = data.aws_subnets.public-subnets.ids[0]
}

resource "local_sensitive_file" "client-config" {
  filename = "client-config.ovpn"

  content = <<-EOT
  client
  dev tun
  proto udp
  remote ${trimprefix(aws_ec2_client_vpn_endpoint.vpn_endpoint.dns_name, "*.")} 1194
  remote-random-hostname
  resolv-retry infinite
  nobind
  remote-cert-tls server
  cipher AES-256-GCM
  verb 3
  dhcp-option DNS ${cidrhost(data.aws_vpc.this.cidr_block, 2)}
  <ca>
  ${var.client-cert.ca_certificate}
  </ca>
  <cert>
  ${var.client-cert.certificate}
  </cert>
  <key>
  ${var.client-cert.key}
  </key>
  reneg-sec 0
  verify-x509-name ${var.client-cert.common_name} name

  EOT
}