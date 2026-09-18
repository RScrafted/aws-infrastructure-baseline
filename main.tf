# =============================================================================
# 1. NETWORKING CORE
# Focus: The virtual data center, subnets, and internet routing.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC: The main isolation boundary
# -----------------------------------------------------------------------------

# Module (instance) name can be anything. Use this same name when referencing outputs.
# (e.g. If module "networks" then use module.network.vpc_id).
# The name vpc is not referring to the folder (/modules/vpc) itself.
# It is the label you give to the module instance so you can reference it later.
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  tags         = var.tags
}


# =============================================================================
# 2. SECURITY GROUPS (FIREWALLS)
# Focus: Defining 'The Containers' and traffic policies (Rules)
# =============================================================================

module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  tags         = var.tags
}

# =============================================================================
# 3. LOAD BALANCER & AUTO SCALING
# Focus: High availability and traffic distribution
# =============================================================================

# -----------------------------------------------------------------------------
# ALB: Distributing incoming web requests
# -----------------------------------------------------------------------------

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  tags              = var.tags
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# -----------------------------------------------------------------------------
# ASG: Managing the fleet of application servers
# -----------------------------------------------------------------------------

module "asg" {
  source                  = "./modules/asg"
  project_name            = var.project_name
  tags                    = var.tags
  ec2_sg_id               = module.security_groups.ec2_sg_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  aws_lb_target_group_arn = module.alb.aws_lb_target_group_arn
}