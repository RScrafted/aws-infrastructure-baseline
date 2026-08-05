# -----------------------------------------------------------------------------
# SECURITY GROUPS: The logical firewall containers
# -----------------------------------------------------------------------------

## ALB Security Group - "The Front Door" (Public access)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = var.vpc_id

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
  vpc_id      = var.vpc_id

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