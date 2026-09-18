# -----------------------------------------------------------------------------
# ALB: Distributing incoming web requests
# -----------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]       # [module.security_groups.alb_sg_id]
  subnets            = var.public_subnet_ids # module.vpc.public_subnet_ids

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
  vpc_id   = var.vpc_id

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