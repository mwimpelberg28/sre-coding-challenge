terraform {
  # Intentionally empty. Will be filled by Terragrunt.
  backend "s3" {
    bucket = "mwimpelberg-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "us-west-2"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.tags
}