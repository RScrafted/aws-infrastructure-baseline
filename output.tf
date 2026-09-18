# --- 1. THE MAIN ENTRY POINT ---

output "alb_dns_name" {
  description = "The public DNS name of the Load Balancer. Use this to visit your website!"
  value       = "http://${module.alb.alb_dns_name}"
}

# # --- 2. NETWORKING DETAILS (For Troubleshooting) ---

# output "public_subnet_ids" {
#   description = "List of IDs for the Public Subnets (where the ALB lives)"
#   value       = module.vpc.public_subnet_ids # [aws_subnet.public_a.id, aws_subnet.public_b.id]
# }

# output "private_subnet_ids" {
#   description = "List of IDs for the Private Subnets (where the EC2s live)"
#   value       = module.vpc.private_subnet_ids # [aws_subnet.private_a.id, aws_subnet.private_b.id]
# }

# # --- 3. SECURITY & SCALING ---

# output "asg_name" {
#   description = "The name of the Auto Scaling Group"
#   value       = aws_autoscaling_group.app_asg.name
# }

# output "nat_gateway_public_ip" {
#   description = "The Static Public IP (EIP) used by our NAT Gateway for outbound updates"
#   value       = module.vpc.nat_gateway_public_ip # aws_eip.nat.public_ip
# }

# # --- 4. AMI ID and Name ---

# output "ami_id" {
#   value = data.aws_ami.al2023.id
# }

# output "ami_name" {
#   value = data.aws_ami.al2023.name
# }