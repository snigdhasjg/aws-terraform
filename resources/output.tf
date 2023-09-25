#output "dns" {
#  value = module.aws-ec2.ec2_public_dns
#}

#output "ssh_command" {
#  value = module.aws-ec2.ssh_command
#}

output "vpc_id" {
  value = module.aws-network.vpc_id
}
