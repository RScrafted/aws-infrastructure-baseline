# =============================================================================
# 1. NETWORK INFRASTRUCTURE
# Core networking topology: VPC isolation, public/private subnets, and routing.
# =============================================================================

# Module instance name—can be anything you choose, and is used to reference outputs
# (e.g., if named "vpc", reference outputs via module.vpc.vpc_id).
# The name `vpc` is not referring to the folder (/modules/vpc) itself.
# It is the label you give to the module instance so you can reference it later. 
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  tags         = var.tags
}

# =============================================================================
# 2. NETWORK SECURITY & ACCESS CONTROL
# Stateful firewalls defining ingress/egress rules across architectural tiers.
# =============================================================================

# SG module establishes security perimeters for ALB (public) and EC2 (private).
module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  tags         = var.tags
}

# =============================================================================
# 3. HIGH AVAILABILITY & COMPUTE ORCHESTRATION
# Application delivery, load balancing, and auto-scaling compute fleets.
# =============================================================================

# Layer 7 Application Load Balancer sitting in public subnets to handle incoming traffic.
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  tags              = var.tags
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# Auto Scaling Group managing EC2 instances in isolated private subnets attached to ALB target group.
module "asg" {
  source                  = "./modules/asg"
  project_name            = var.project_name
  tags                    = var.tags
  ec2_sg_id               = module.security_groups.ec2_sg_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  aws_lb_target_group_arn = module.alb.aws_lb_target_group_arn
}