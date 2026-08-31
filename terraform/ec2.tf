# ===== AMI: latest Ubuntu 24.04  =====
data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# ===== IAM instance profile: allows SSM Session Manager access (no SSH key needed) =====
data "aws_iam_instance_profile" "my_ssm_profile" {
  name = "EC2-SSM-Role"
}

# =====================================================================
# Server 1 - Web server
# Public subnet, gets an Elastic IP, reachable on port 80 from anywhere
# =====================================================================
module "web_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name                   = "web-server-public"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.small"
  subnet_id              = module.my_vpc.public_subnets[0]           # public subnet
  private_ip             = "10.0.0.5"
  create_security_group  = false
  vpc_security_group_ids = [module.devops_public_sg.security_group_id]
  key_name               = "faris-key"
  iam_instance_profile   = data.aws_iam_instance_profile.my_ssm_profile.name
  root_block_device      = { size = 16 }

  tags = { Name = "web-server-public" }
}


resource "aws_eip" "web_server_eip" {
  instance = module.web_server.id
  domain   = "vpc"

  tags = {
    Name = "web-server-public-eip"
  }
}

# =====================================================================
# Server 2 - Ansible controller
# Private subnet
# =====================================================================
module "ansible_controller" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name                   = "controller-ansible"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.small"
  subnet_id              = module.my_vpc.private_subnets[0]    # private subnet
  private_ip             = "10.0.0.135"
  create_security_group  = false
  vpc_security_group_ids = [module.devops_private_sg.security_group_id]
  key_name               = "faris-key"
  iam_instance_profile   = data.aws_iam_instance_profile.my_ssm_profile.name
  root_block_device      = { size = 16 }

  tags = { Name = "controller-ansible" }
}

# =====================================================================
# Server 3 - Monitoring server
# Private subnet, internal-only, scrapes metrics (e.g. node_exporter) from other servers
# =====================================================================
module "monitoring_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name                   = "server-monitoring"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.small"
  subnet_id              = module.my_vpc.private_subnets[0]    # private subnet
  private_ip             = "10.0.0.136"
  create_security_group  = false
  vpc_security_group_ids = [module.devops_private_sg.security_group_id]
  key_name               = "faris-key"
  iam_instance_profile   = data.aws_iam_instance_profile.my_ssm_profile.name
  root_block_device      = { size = 16 }

  tags = { Name = "server-monitoring" }
}