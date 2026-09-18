# =============================================================================
# TERRAFORM PROVIDER CONFIGURATION
# Core provider requirements, version locking, and AWS profile management.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS Provider instance binding environment-specific profiles and target regions.
provider "aws" {
  profile = var.env
  region  = var.aws_region
}