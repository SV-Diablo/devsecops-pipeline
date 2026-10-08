terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local state keeps the demo self-contained. For a team, use an S3 backend
  # with use_lockfile = true and a bucket that has versioning and encryption.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project    = var.project
      ManagedBy  = "terraform"
      Repository = var.github_repository
    }
  }
}
