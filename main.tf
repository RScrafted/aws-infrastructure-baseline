# =============================================================================
# 1. NETWORKING CORE
# Focus: The virtual data center, subnets, and internet routing.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC: The main isolation boundary
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

## Optional: Adopting the AWS-created Default Route Table for the VPC
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = merge(
    var.tags,
    { Name = "${var.project_name}-default-rt" }
  )
}

# -----------------------------------------------------------------------------
# SUBNETS: Segmenting the network into Public and Private tiers
# -----------------------------------------------------------------------------

## Public Subnets - Tier for Internet-facing resources (ALB)
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "eu-west-2a"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-sn-a"
    }
  )
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "eu-west-2b"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-sn-b"
    }
  )
}

## Private Subnets - Tier for restricted resources (EC2/ASG)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "eu-west-2a"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-sn-a"
    }
  )
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.20.0/24"
  availability_zone = "eu-west-2b"
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-sn-b"
    }
  )
}

# -----------------------------------------------------------------------------
# GATEWAYS: Handling ingress (IGW) and egress (NAT)
# -----------------------------------------------------------------------------

## Internet Gateway - Allows the VPC to speak to the world
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

## Elastic IP - Static address required for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-eip"
    }
  )
}

## NAT Gateway - Allows Private Subnets to reach the internet for updates
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Must live in Public to work
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat"
    }
  )
}

# -----------------------------------------------------------------------------
# ROUTING: Defining how traffic flows between subnets and gateways
# -----------------------------------------------------------------------------

## Public Route Table - Routes 0.0.0.0/0 to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

## Private Route Table - Routes 0.0.0.0/0 to the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-rt"
    }
  )
}

## Associations - Linking Route Tables to specific Subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


# =============================================================================
# 2. SECURITY GROUPS (FIREWALLS)
# Focus: Defining 'The Containers' and traffic policies (Rules)
# =============================================================================

# -----------------------------------------------------------------------------
# SECURITY GROUPS: The logical firewall containers
# -----------------------------------------------------------------------------

## ALB Security Group - "The Front Door" (Public access)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-sg"
    }
  )
}

## EC2 Security Group - "The Private Room" (ALB access only)
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for private app servers"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2_sg"
    }
  )
}

# -----------------------------------------------------------------------------
# TRAFFIC RULES: Granular Ingress/Egress policies
# -----------------------------------------------------------------------------

## ALB Rules: Standard web traffic entry
## `aws_vpc_security_group_ingress_rule` ports depends on `aws_lb_listener` configuration.
resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-http-in"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 means 'all protocols'

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-all-out"
    }
  )
}

## EC2 Rules: Highly restricted traffic path (The ID Badge check)
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ec2_sg.id
  description                  = "Allow HTTP traffic from ALB only"
  referenced_security_group_id = aws_security_group.alb_sg.id # The ID Badge!
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2_http_from_alb"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "ec2_all_out" {
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Allow all outbound (for software updates via NAT)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2_all_out"
    }
  )
}


# =============================================================================
# 3. LOAD BALANCER & AUTO SCALING
# Focus: High availability and traffic distribution
# =============================================================================

# -----------------------------------------------------------------------------
# ALB: Distributing incoming web requests
# -----------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # Uncomment for Production Release
  /*
  enable_deletion_protection = true
  
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }
  */

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb"
    }
  )

}

## Target Group - The "Waiting Room" where instances report for health checks
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 80 # Protocol for communication between the Load Balancers and Targets
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Production Requirement: Define how to check if the app is alive
  health_check {
    enabled             = true
    path                = "/"   # Hits the index page
    interval            = 30    # The approximate amount of time between health checks of an individual target. 30 seconds
    timeout             = 5     # The amount of time, in seconds, during which no response means a failed health check.
    healthy_threshold   = 2     # The number of consecutive health checks successes required before considering an unhealthy target healthy.
    unhealthy_threshold = 2     # The number of consecutive health check failures required before considering a target unhealthy.
    matcher             = "200" # Expects a "Success" code
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-tg"
    }
  )
}

## Listener - The Load Balancer's "Ear" listening on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
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

  vpc_security_group_ids = [aws_security_group.ec2_sg.id] # NSG attached

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
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id] # Keep workers private!

  # Wait for the ALB to say the instance is "Healthy" before counting it
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # This connects the ASG to the Load Balancer waiting room
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}