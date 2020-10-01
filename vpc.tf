## VPC Module
module "main-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  # The rest of arguments are omitted for brevity
  name                 = "${var.common["prefix"]}-${var.common["env"]}-vpc"
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = true
  azs                  = var.zones
  enable_nat_gateway   = true
  enable_vpn_gateway   = false

  # public subnets
  public_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  public_subnet_assign_ipv6_address_on_creation = false
  # public_subnet_ipv6_prefixes                   = [0, 1, 2]

  # private subnets
  private_subnets = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]

  # other subnets
  # database_subnets    = ["10.0.128.0/24", "10.0.129.0/24", "10.0.130.0/24"]
  # elasticache_subnets = ["10.0.131.0/24", "10.0.132.0/24", "10.0.133.0/24"]
  # intra_subnets       = ["10.0.134.0/24", "10.0.135.0/24", "10.0.136.0/24"]

  tags = {
    Terraform       = "true",
    TerraformModule = "terraform-aws-modules/vpc/aws",
    Project         = "${var.common["env"]}",
    Owner           = "${var.common["prefix"]}",
  }
}