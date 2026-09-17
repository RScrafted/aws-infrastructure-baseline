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

## Data Source - Finding the latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## Launch Template - The "Blueprint" for every EC2 instance in the fleet
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [module.security_groups.ec2_sg_id] # NSG attached

  # Bootstrapping: Installing and starting the web server on launch
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              # Gets the internal hostname (e.g., ip-10-0-1-50.ec2.internal)
              NAME=$(hostname)

              # Create the index file
              echo "<h1>RScart Baseline: SUCCESS</h1><p>Served by Instance: $NAME</p>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-lt"
      }
    )
  }
}

## Auto Scaling Group - The "Manager" handling capacity and AZ failover
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  max_size            = 4
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = module.vpc.private_subnet_ids # Keep workers private!

  # Wait for the ALB to say the instance is "Healthy" before counting it
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # This connects the ASG to the Load Balancer waiting room
  target_group_arns = [module.alb.aws_lb_target_group_arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}