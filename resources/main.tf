#module "tls" {
#  source       = "./modules/tls"
#  cert_details = {
#    common_name = "joe.in",
#    dns_names   = [
#      "localhost",
#      "*.joe.in"
#    ]
#  }
#}

module "aws-network" {
  source = "./modules/aws-network"

  create_nat_gateway       = false
  vpc_cidr_block           = "10.2.0.0/20"
  tag_prefix               = "joe"
  no_of_private_subnet = 3
  no_of_public_subnet  = 2
  private_endpoint_gateways = [
#    "s3"
  ]
  private_endpoint_interfaces = [
#    "email-smtp",
#    "ecr.api",
#    "ecr.dkr"
  ]
}