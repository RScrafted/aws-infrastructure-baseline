variable "project_name" {
  type        = string
  description = "Base prefix assigned to infrastructure resource naming conventions"
}

variable "tags" {
  type        = map(string)
  description = "Standardized key-value map for resource governance and cost tracking"
}

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}