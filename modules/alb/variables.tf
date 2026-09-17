# Project name and tags are common for all modules
variable "project_name" {
  type        = string
  description = "Base project name for tagging and naming"
}

variable "tags" {
  type = map(string)
}

# VPC Variables

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}