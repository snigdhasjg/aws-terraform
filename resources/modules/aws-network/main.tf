resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.tag_prefix}-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = {
    for idx in range(var.no_of_public_subnet) : idx => {
      availability_zone = data.aws_availability_zones.this.names[idx % length(data.aws_availability_zones.this.names)]
      cidr_block        = cidrsubnet(local.public_subnets_allocated_cidr, ceil(pow(var.no_of_public_subnet, 1/2)), idx)
    }
  }

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.cidr_block

  tags = {
    Name         = "${var.tag_prefix}-public-subnet-${trimprefix(each.value.availability_zone, data.aws_region.this.name)}"
    connectivity = "public"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = {
    for idx in range(var.no_of_private_subnet) : idx => {
      availability_zone = data.aws_availability_zones.this.names[idx % length(data.aws_availability_zones.this.names)]
      cidr_block        = cidrsubnet(local.private_subnets_allocated_cidr, ceil(pow(var.no_of_private_subnet, 1/2)), idx)
    }
  }

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.cidr_block

  tags = {
    Name         = "${var.tag_prefix}-private-subnet-${trimprefix(each.value.availability_zone, data.aws_region.this.name)}"
    connectivity = "private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.tag_prefix}-igw"
  }
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.tag_prefix}-default-private-route-table"
  }
}

resource "aws_eip" "public_ip_nat_gw" {
  count = var.create_nat_gateway ? 1 : 0

  tags = {
    Name = "${var.tag_prefix}-public-ip-natgw"
  }
}

resource "aws_nat_gateway" "public_nat" {
  count = var.create_nat_gateway ? 1 : 0

  subnet_id     = aws_subnet.public_subnets[0].id
  allocation_id = aws_eip.public_ip_nat_gw[0].id

  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_route_table_association
  ]

  tags = {
    Name = "${var.tag_prefix}-natgw"
  }
}

resource "aws_route_table_association" "nat_association" {
  count          = var.create_nat_gateway ? 1 : 0
  route_table_id = aws_default_route_table.this.id
  gateway_id     = aws_nat_gateway.public_nat[0].id
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

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow all traffic within itself"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  ingress {
    description = "Allow all traffic from Joe public IP"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${chomp(data.http.my-public-ip.body)}/32"]
  }

  egress {
    description = "Allow all external traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_prefix}-default-sg"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "vpc_endpoint_interface_sg" {
  count = length(var.private_endpoint_interfaces) > 0 ? 1 : 0

  name   = "vpc-endpoint-interface-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow all traffic from same VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description = "Allow all traffic within itself"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  egress {
    description = "Allow all external traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_prefix}-vpc-endpoint-interface-sg"
  }
}

resource "aws_vpc_endpoint" "private_endpoint_interfaces" {
  for_each = var.private_endpoint_interfaces

  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.this.name}.${each.key}"

  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.public_subnets[0].id]

  security_group_ids = [
    aws_security_group.vpc_endpoint_interface_sg[0].id
  ]

  private_dns_enabled = true

  tags = {
    Name = "${var.tag_prefix}-${each.key}-interface"
  }
}

resource "aws_vpc_endpoint" "private_endpoint_gateways" {
  for_each = var.private_endpoint_gateways

  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.this.name}.${each.key}"

  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.tag_prefix}-${each.key}-gateway"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_endpoint_gateway_association" {
  for_each = {
    for object in flatten([
      for vpc_service, vpc_gateway in aws_vpc_endpoint.private_endpoint_gateways : [
        for route_type, route_table_id in {
          default_route = aws_default_route_table.this.id
          public_route  = aws_route_table.public_route_table.id
        } : {
          combined_key   = "${vpc_service}_${route_type}",
          route_table_id = route_table_id,
          vpc_gateway_id = vpc_gateway.id
        }
      ]
    ]) : object.combined_key => {
      route_table_id = object.route_table_id,
      vpc_gateway_id = object.vpc_gateway_id
    }
  }

  route_table_id  = each.value.route_table_id
  vpc_endpoint_id = each.value.vpc_gateway_id
}