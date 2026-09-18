variable "project_name" {
  type        = string
  description = "Base prefix assigned to infrastructure resource naming conventions"
}

variable "tags" {
  type        = map(string)
  description = "Standardized key-value map for resource governance and cost tracking"
}

# VPC Variables

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.20.0.0/16"
}