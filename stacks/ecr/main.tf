################################################################################
# ECR Stack — SIMULATED
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

module "tags" {
  source       = "../../modules/tags"
  project_name = var.project_name
  environment  = var.environment
}

resource "random_id" "ecr" {
  byte_length = 6
  keepers = {
    repo_name = "${var.project_name}-${var.environment}-app"
    region    = var.region
  }
}

# Simulated ECR Repository
resource "null_resource" "ecr_repo" {
  triggers = {
    name                 = "${var.project_name}-${var.environment}-app"
    image_tag_mutability = var.image_tag_mutability
    scan_on_push         = "true"
  }
}

# Simulated Lifecycle Policy
resource "null_resource" "lifecycle_policy" {
  triggers = {
    repository      = null_resource.ecr_repo.triggers.name
    retention_count = tostring(var.image_retention_count)
  }
}
