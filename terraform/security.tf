# =====================================================================
# Public Security Group
# Applied to: web server public 10.0.0.5
# Rules: HTTP from anywhere, node_exporter from monitoring server, SSH from VPC
# =====================================================================
module "devops_public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "devops-public-sg"
  description = "Public SG - HTTP from anywhere, node_exporter from monitoring, SSH from VPC"
  vpc_id      = module.my_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      description = "Node exporter from monitoring server"
      cidr_blocks = "10.0.0.136/32"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPC subnet"
      cidr_blocks = module.my_vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name = "devops-public-sg"
  }
}

# =====================================================================
# Private Security Group
# Applied to: Ansible controller, monitoring server
# Rules: SSH from VPC only (no public exposure)
# =====================================================================
module "devops_private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "devops-private-sg"
  description = "Private SG - SSH only from within VPC"
  vpc_id      = module.my_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPC subnet"
      cidr_blocks = module.my_vpc.vpc_cidr_block
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name = "devops-private-sg"
  }
}