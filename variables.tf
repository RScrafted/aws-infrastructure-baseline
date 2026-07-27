variable "env" {
  type        = string
  description = "Environment for Deployment"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Base project name for tagging and naming"
  default     = "RScart-dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-2"
}

variable "tags" {
  type = map(string)
  default = {
    Project      = "RScart-dev"
    Environment  = "dev"
    Backend-Team = "q1-dev"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.20.0.0/16"
}