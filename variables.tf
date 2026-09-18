variable "env" {
  type        = string
  description = "Environment for Deployment"
  default     = "admin-rachit"
}

variable "project_name" {
  type        = string
  description = "Base project name for tagging and naming"
  default     = "RScart"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-2"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "RScart"
    Environment = "dev"
    Owner       = "backend-team"
  }
}