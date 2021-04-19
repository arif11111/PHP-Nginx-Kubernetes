// Configure AWS VPC, Subnets, and Routes

module "vpc" {
  version = "v2.7.0"
  source  = "terraform-aws-modules/vpc/aws"

  name = "${ var.name }"
  cidr = "${ var.vpc_subnet }"

  azs            = "${ var.azs }"
  public_subnets = "${ var.public_subnets }"
  private_subnets = "${ var.private_subnets }"
  database_subnets = "${ var.database_subnets }"

  enable_nat_gateway                = true 
  single_nat_gateway                = true
  one_nat_gateway_per_az            = false
  propagate_public_route_tables_vgw = true
  enable_dns_hostnames              = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
