variable "project_name" {
  type        = string
  description = "Base prefix assigned to infrastructure resource naming conventions"
}

variable "tags" {
  type        = map(string)
  description = "Standardized key-value map for resource governance and cost tracking"
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