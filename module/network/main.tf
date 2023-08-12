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
  map_public_ip_on_launch = true
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