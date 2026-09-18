# Project name and tags are common for all modules
variable "project_name" {
  type        = string
  description = "Base project name for tagging and naming"
}

variable "tags" {
  type = map(string)
}

variable "ec2_sg_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "aws_lb_target_group_arn" {
  type = string
}