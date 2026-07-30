# Project name and tags are common for all modules
variable "project_name" {
  type        = string
  description = "Base project name for tagging and naming"
}

variable "tags" {
  type = map(string)
}

# VPC Variables

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.20.0.0/16"
}