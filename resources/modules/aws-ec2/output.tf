output "ec2_public_dns" {
  value = aws_instance.this.public_dns
}

output "ssh_command" {
  value = "ssh -i ${local_file.private_key_file.filename} ecc2-user@${aws_instance.this.id}"
}
