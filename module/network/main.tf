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