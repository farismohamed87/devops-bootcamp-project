# =====================================================================
# AWS Account / Caller Identity
# =====================================================================
output "aws_account_id" {
  description = "AWS Account ID Terraform is currently authenticated against"
  value       = data.aws_caller_identity.my_account.account_id
}

output "aws_caller_arn" {
  description = "IAM ARN of the identity Terraform is using"
  value       = data.aws_caller_identity.my_account.arn
}

# =====================================================================
# Networking
# =====================================================================
output "vpc_id" {
  description = "ID of the devops-vpc"
  value       = module.my_vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.my_vpc.vpc_cidr_block
}

output "public_subnet_id" {
  description = "ID of devops-public-subnet"
  value       = module.my_vpc.public_subnets[0]
}

output "private_subnet_id" {
  description = "ID of devops-private-subnet"
  value       = module.my_vpc.private_subnets[0]
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (devops-ngw)"
  value       = module.my_vpc.nat_public_ips[0]
}

# =====================================================================
# Security Groups
# =====================================================================
output "public_sg_id" {
  description = "ID of devops-public-sg"
  value       = module.devops_public_sg.security_group_id
}

output "private_sg_id" {
  description = "ID of devops-private-sg"
  value       = module.devops_private_sg.security_group_id
}

# =====================================================================
# EC2 Instances
# =====================================================================
output "web_server_id" {
  description = "Instance ID of the web server"
  value       = module.web_server.id
}

output "web_server_private_ip" {
  description = "Private IP of the web server"
  value       = module.web_server.private_ip
}

output "web_server_public_eip" {
  description = "Elastic IP (public) attached to the web server"
  value       = aws_eip.web_server_eip.public_ip
}

output "ansible_controller_id" {
  description = "Instance ID of the Ansible controller"
  value       = module.ansible_controller.id
}

output "ansible_controller_private_ip" {
  description = "Private IP of the Ansible controller (10.0.0.135)"
  value       = module.ansible_controller.private_ip
}

output "monitoring_server_id" {
  description = "Instance ID of the monitoring server"
  value       = module.monitoring_server.id
}

output "monitoring_server_private_ip" {
  description = "Private IP of the monitoring server (10.0.0.136)"
  value       = module.monitoring_server.private_ip
}

# =====================================================================
# Convenience output - ready-to-use Ansible inventory targets
# =====================================================================
output "ansible_inventory_targets" {
  description = "Private IPs of hosts the Ansible controller should manage"
  value = {
    webserver  = module.web_server.private_ip
    monitoring = module.monitoring_server.private_ip
  }
}