# --- SECURITY & SCALING ---

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

# --- AMI ID and Name ---

output "ami_id" {
  value = data.aws_ami.al2023.id
}

output "ami_name" {
  value = data.aws_ami.al2023.name
}