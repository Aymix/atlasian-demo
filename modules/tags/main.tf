################################################################################
# Tags Module
# Provides a consistent set of tags across all stacks
################################################################################

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

output "common_tags" {
  description = "Map of common tags to apply to all resources"
  value = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "atlasian-demo"
  }
}
