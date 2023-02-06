resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.tag_prefix}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = {for idx, az in range(var.max_no_of_public_subnet) : az => idx}

  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.availability_zones[each.key % length(local.availability_zones)]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, local.no_of_bit_to_fix, 0 + each.key)

  tags = {
    Name         = "${var.tag_prefix}-public-subnet-${trimprefix(local.availability_zones[each.key % length(local.availability_zones)], data.aws_region.current.name)}"
    connectivity = "public"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = {for idx, az in range(var.max_no_of_private_subnet) : az => idx}

  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.availability_zones[each.key % length(local.availability_zones)]
  cidr_block        = cidrsubnet(var.vpc_cidr_block, local.no_of_bit_to_fix, var.max_no_of_public_subnet + each.key)

  tags = {
    Name         = "${var.tag_prefix}-private-subnet-${trimprefix(local.availability_zones[each.key % length(local.availability_zones)], data.aws_region.current.name)}"
    connectivity = "private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.tag_prefix}-igw"
  }
}

resource "aws_nat_gateway" "public_nat" {
  count = var.create_nat_gateway ? 1 : 0
  subnet_id     = aws_subnet.public_subnet[0].id
  allocation_id = aws_eip.public_ip_nat_gw[0].id

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_route_table_association
  ]

  tags = {
    Name = "${var.tag_prefix}-natgw"
  }
}

resource "aws_eip" "public_ip_nat_gw" {
  count = var.create_nat_gateway ? 1 : 0
  tags = {
    Name = "${var.tag_prefix}-public-ip-natgw"
  }
}

resource "aws_default_route_table" "default" {
  count = var.create_nat_gateway ? 1 : 0
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_nat[0].id
  }

  tags = {
    Name = "${var.tag_prefix}-default-route-table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.tag_prefix}-public-route-table"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow all traffic within itself"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  egress {
    description = "Allow all ipv4 to connect to"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all ipv6 to connect to"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.tag_prefix}-default-sg"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}