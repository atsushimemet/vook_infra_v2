#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------
resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-vpc"
  }
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "${var.name}-igw"
  }
}

#--------------------------------------------------------------
# Elastic IP
#--------------------------------------------------------------
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.default]
}

#--------------------------------------------------------------
# Public subnet
#--------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = var.pub_cidrs

  vpc_id                  = aws_vpc.default.id
  cidr_block              = each.value
  availability_zone       = "${var.region}${each.key}"
  # map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
  tags = {
    Name = "${var.name}-public-rtb"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
#--------------------------------------------------------------
# NAT
#--------------------------------------------------------------
resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["a"].id
  depends_on    = [aws_internet_gateway.default]
}

#--------------------------------------------------------------
# Private subnet
#--------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = var.pri_cidrs

  vpc_id                  = aws_vpc.default.id
  cidr_block              = each.value
  availability_zone       = "${var.region}${each.key}"
  # map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default.id
  }
  tags = {
    Name = "${var.name}-private-rtb"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}