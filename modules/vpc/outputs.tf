output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for the Public Subnets (where the ALB lives)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of IDs for the Private Subnets (where the EC2s live)"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_public_ip" {
  description = "The Static Public IP (EIP) used by our NAT Gateway for outbound updates"
  value       = aws_eip.nat.public_ip
}