module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16.0"

  name                 = local.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.aws_availability_zones
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  default_security_group_ingress = [
    {
      "from_port" : 0,
      "to_port" : 0,
      "protocol" : -1,
      "self" : true,
      "cidr_blocks" : "0.0.0.0/0",
    }
  ]
  default_security_group_egress = [
    {
      "from_port" : 0,
      "to_port" : 0,
      "protocol" : -1,
      "cidr_blocks" : "0.0.0.0/0",
    }
  ]

  tags = {
    "Environment" = "production"
  }


}
