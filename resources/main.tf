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

module "aws-network" {
  source = "./modules/aws-network"

  create_nat_gateway        = false
  vpc_cidr_block            = "10.2.0.0/20"
  tag_prefix                = "joe"
  no_of_private_subnet      = 3
  no_of_public_subnet       = 2
  private_endpoint_gateways = [
    #    "s3"
  ]
  private_endpoint_interfaces = [
    #    "email-smtp",
    #    "ecr.api",
    #    "ecr.dkr"
  ]
}

module "aws-ec2" {
  source = "./modules/aws-ec2"


  instance_type = "g4dn.xlarge"
  tag_prefix    = "joe"
  vpc_id        = module.aws-network.vpc_id
  ami_type      = "AMAZON_LINUX_2"
}

#module "aws-openvpn" {
#  source = "./modules/aws-openvpn"
#
#  tag_prefix  = "joe"
#  vpc-id      = module.aws-network.vpc_id
#  server-cert = module.server-tls.cert
#}

#module "aws-vpn" {
#  source = "./modules/aws-vpn"
#
#  vpn_cidr_block = "10.3.0.0/22"
#  client-cert    = module.client-tls.cert
#  server-cert    = module.server-tls.cert
#  tag_prefix     = "joe"
#  vpc-id         = module.aws-network.vpc_id
#}

#module "aws-s3" {
#  source = "./modules/aws-s3"
#
#  bucket_name             = "cross-account-bucket"
#  tag_prefix              = "joe"
#  cross_account_principal = "arn:aws:iam::123456789012:role/ec2-service-role"
#}