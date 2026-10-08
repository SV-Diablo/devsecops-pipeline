variable "region" {
  description = "AWS region for every resource."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name prefix for every resource."
  type        = string
  default     = "devsecops-pipeline"
}

variable "github_repository" {
  description = "owner/repo allowed to assume the deploy role through OIDC."
  type        = string
  default     = "SV-Diablo/devsecops-pipeline"
}

variable "github_environment" {
  description = "GitHub environment the deploy job runs in. Only that environment can assume the role."
  type        = string
  default     = "production"
}

variable "create_github_oidc_provider" {
  description = "Set to false if the account already has the token.actions.githubusercontent.com provider."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs that may reach the API on port 8000. Empty = not reachable from the internet."
  type        = list(string)
  default     = []
}

variable "desired_count" {
  description = "Running tasks. Start at 0, deploy the first image from CI, then raise to 1."
  type        = number
  default     = 0
}

variable "image_tag" {
  description = "Tag used by the bootstrap task definition. CI registers new revisions with the commit SHA."
  type        = string
  default     = "bootstrap"
}
