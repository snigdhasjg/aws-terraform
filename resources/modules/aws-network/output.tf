output "vpc_id" {
  depends_on = [
    aws_subnet.private_subnets,
    aws_subnet.public_subnets
  ]

  value = aws_vpc.vpc.id
}