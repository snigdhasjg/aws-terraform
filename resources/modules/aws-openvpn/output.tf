output "ec2_public_host" {
  value = aws_instance.openvpn_ec2.public_dns
}

output "dns" {
  value = cidrhost(data.aws_vpc.this.cidr_block, 2)
}

output "ssh_command" {
  value = "ssh -i ${local_file.private_key_file.filename} ubuntu@${aws_instance.openvpn_ec2.id}"
}