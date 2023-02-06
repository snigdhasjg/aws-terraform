variable "create_nat_gateway" {
  description = "Flag to create nat_gateway for private subnet"
  type = bool
}

variable "vpc_cidr_block" {
  description = "CIDR block of VPC"
  type        = string
  validation {
    condition = can(cidrhost(var.vpc_cidr_block, 32))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "tag_prefix" {
  description = "Resource tag prefix"
  type        = string
}

variable "max_no_of_public_subnet" {
  description = "No of public subnet to create"
  type        = number
}

variable "max_no_of_private_subnet" {
  description = "No of private subnet to create"
  type        = number
}

locals {
  no_of_bit_to_fix   = ceil(pow(var.max_no_of_private_subnet + var.max_no_of_public_subnet, 1/2))
  availability_zones = slice(data.aws_availability_zones.az.names, 0, 3)
}