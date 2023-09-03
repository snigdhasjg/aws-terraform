locals {
  owner      = "Snigdhajyoti Ghosh"
  tag_prefix = "joe"
}

#module "client-tls" {
#  source = "./modules/tls"
#
#  certificate_common_name = "joe.in"
#  certificate_dns_names   = [
#    "localhost",
#    "*.joe.in"
#  ]
#}

#module "server-tls" {
#  source = "./modules/tls"
#
#  certificate_common_name = "amazonaws.com"
#  certificate_dns_names   = [
#    "*.amazonaws.com",
#    "*.local",
#    "*.internal"
#  ]
#}

#module "aws-network" {
#  source = "./modules/aws-network"
#
#  owner                     = local.owner
#  tag_prefix                = local.tag_prefix
#  create_nat_gateway        = false
#  vpc_cidr_block            = "10.2.0.0/20"
#  no_of_private_subnet      = 3
#  no_of_public_subnet       = 2
#  private_endpoint_gateways = [
#    #    "s3"
#  ]
#  private_endpoint_interfaces = [
#    #    "email-smtp",
#    #    "ecr.api",
#    #    "ecr.dkr"
#  ]
#}

#module "aws-ec2" {
#  source = "./modules/aws-ec2"
#
#  owner         = local.owner
#  tag_prefix    = local.tag_prefix
#  instance_type = "g4dn.xlarge"
#  vpc_id        = module.aws-network.vpc_id
#  ami_type      = "AMAZON_LINUX_2"
#}

#module "aws-openvpn" {
#  source = "./modules/aws-openvpn"
#
#  owner       = local.owner
#  tag_prefix  = local.tag_prefix
#  vpc-id      = module.aws-network.vpc_id
#  server-cert = module.server-tls.cert
#}

#module "aws-vpn" {
#  source = "./modules/aws-vpn"
#
#  owner          = local.owner
#  tag_prefix     = local.tag_prefix
#  vpn_cidr_block = "10.3.0.0/22"
#  client-cert    = module.client-tls.cert
#  server-cert    = module.server-tls.cert
#  vpc-id         = module.aws-network.vpc_id
#}

module "aws-s3" {
  source = "./modules/aws-s3"

  owner                   = local.owner
  tag_prefix              = local.tag_prefix
  bucket_name             = "twer-cross-account-bucket"
  cross_account_principal = "160071257600"
}