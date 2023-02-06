module "aws-network" {
  source = "./modules/aws-network"

  create_nat_gateway       = false
  vpc_cidr_block           = "10.2.0.0/20"
  tag_prefix               = "joe"
  max_no_of_private_subnet = 3
  max_no_of_public_subnet  = 2
}