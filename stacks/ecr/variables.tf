variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "atlasian-demo"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository"
  type        = string
  default     = "MUTABLE"
}

variable "image_retention_count" {
  description = "Number of images to keep in the repository"
  type        = number
  default     = 10
}
