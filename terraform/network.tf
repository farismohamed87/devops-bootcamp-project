# =====================================================================
# VPC - devops-vpc
# Public subnet (10.0.0.0/25) + private subnet (10.0.0.128/25)
# IGW for public egress, single NAT Gateway for private egress
# =====================================================================
module "my_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "devops-vpc"
  cidr = "10.0.0.0/24"

  azs             = [var.az]
  public_subnets  = ["10.0.0.0/25"]
  private_subnets = ["10.0.0.128/25"]

  # Public subnet: auto-assign public IP on launch (map_public_ip_on_launch)
  map_public_ip_on_launch = true

  # NAT Gateway for private subnet egress
  enable_nat_gateway = true
  single_nat_gateway = true   # one shared NAT GW (matches your original single aws_nat_gateway)
  one_nat_gateway_per_az = false

  # Internet Gateway is created automatically when public_subnets is non-empty

  tags = {
    Project = "devops-bootcamp"
  }

  vpc_tags = {
    Name = "devops-vpc"
  }

  igw_tags = {
    Name = "devops-igw"
  }

  nat_gateway_tags = {
    Name = "devops-ngw"
  }

  nat_eip_tags = {
    Name = "devops-nat-eip"
  }

  public_subnet_tags = {
    Name = "devops-public-subnet"
  }

  private_subnet_tags = {
    Name = "devops-private-subnet"
  }

  public_route_table_tags = {
    Name = "devops-public-route"
  }

  private_route_table_tags = {
    Name = "devops-private-route"
  }
}