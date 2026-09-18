# =============================================================================
# GLOBAL CONFIGURATION VARIABLES
# Core inputs governing deployment metadata, region selection, and default tags.
# =============================================================================

variable "env" {
  type        = string
  description = "Deployment target environment (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Base prefix used across infrastructure resource naming conventions"
  default     = "RScart"
}

variable "aws_region" {
  type        = string
  description = "Target AWS region for infrastructure deployment"
  default     = "eu-west-2"
}

variable "tags" {
  type        = map(string)
  description = "Standardized map of resource tags for allocation, governance, and tracking"
  default = {
    Project     = "RScart"
    Environment = "dev"
    Owner       = "backend-team"
  }
}