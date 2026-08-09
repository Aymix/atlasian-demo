################################################################################
# IAM Stack — SIMULATED
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

resource "random_id" "iam" {
  byte_length = 6
  keepers = {
    project = var.project_name
    env     = var.environment
    region  = var.region
  }
}

# Simulated ECS Task Execution Role
resource "null_resource" "ecs_task_execution_role" {
  triggers = {
    name = "${var.project_name}-${var.environment}-ecs-execution"
  }
}

# Simulated ECS Task Role
resource "null_resource" "ecs_task_role" {
  triggers = {
    name = "${var.project_name}-${var.environment}-ecs-task"
  }
}

# Simulated CloudWatch policy
resource "null_resource" "cloudwatch_policy" {
  triggers = {
    name = "${var.project_name}-${var.environment}-ecs-task-logs"
    role = null_resource.ecs_task_role.triggers.name
  }
}
