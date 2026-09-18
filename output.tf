# =============================================================================
# ENTRYPOINT OUTPUTS
# Publicly accessible endpoints for application delivery.
# =============================================================================

output "alb_dns_name" {
  description = "Fully qualified domain name / HTTP endpoint for the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

# =============================================================================
# NETWORK & INFRASTRUCTURE DIAGNOSTICS
# Useful outputs for cross-module validation and operational inspection.
# =============================================================================

output "public_subnet_ids" {
  description = "List of public subnet IDs housing the ingress load balancer"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs housing application compute instances"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_public_ip" {
  description = "Elastic IP address of the NAT Gateway handling outbound egress traffic"
  value       = module.vpc.nat_gateway_public_ip # aws_eip.nat.public_ip
}