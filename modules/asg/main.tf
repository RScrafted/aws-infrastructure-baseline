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

  vpc_security_group_ids = [var.ec2_sg_id] # NSG attached

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
  vpc_zone_identifier = var.private_subnet_ids # module.vpc.private_subnet_ids # Keep workers private!

  # Wait for the ALB to say the instance is "Healthy" before counting it
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # This connects the ASG to the Load Balancer waiting room
  target_group_arns = [var.aws_lb_target_group_arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}