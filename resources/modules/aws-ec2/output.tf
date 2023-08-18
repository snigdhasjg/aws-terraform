output "ec2_public_dns" {
  value = aws_instance.windows_ec2.public_dns
}
