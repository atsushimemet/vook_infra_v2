variable "region" {}
variable "name" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" { type = map(string) }
variable "private_subnet_cidrs" { type = map(string) }
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

terraform {
  required_version = "=v1.4.0"
}

provider "aws" {
  region = var.region
}

module "network" {
  source = "./module/network"

  name      = var.name
  region    = var.region
  vpc_cidr  = var.vpc_cidr
  pub_cidrs = var.public_subnet_cidrs
  pri_cidrs = var.private_subnet_cidrs
}

module "ec2" {
  source = "./module/ec2"

  app_name   = var.name
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.pub_subnet_ids
  key_name   = "${var.name}-ec2-key"
}

module "rds" {
  source = "./module/rds"

  app_name                  = var.name
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.pri_subnet_ids
  subnet_cidr_blocks        = module.network.pri_subnet_cidr_blocks
  source_security_group_ids = [module.ec2.ec2_security_group_id]
}