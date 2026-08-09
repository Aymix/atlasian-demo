################################################################################
# ECS Stack — SIMULATED
# Depends on: vpc, iam, ecr, alb (conceptually, but decoupled for simulation)
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

resource "random_id" "ecs" {
  byte_length = 8
  keepers = {
    project = var.project_name
    env     = var.environment
  }
}

# Simulated CloudWatch Log Group
resource "null_resource" "log_group" {
  triggers = {
    name              = "/ecs/${var.project_name}-${var.environment}"
    retention_in_days = "14"
  }
}

# Simulated ECS Cluster
resource "null_resource" "cluster" {
  triggers = {
    name               = "${var.project_name}-${var.environment}-cluster"
    container_insights = "enabled"
  }
}

# Simulated ECS Task Definition
resource "null_resource" "task_definition" {
  triggers = {
    family         = "${var.project_name}-${var.environment}-app"
    cpu            = var.task_cpu
    memory         = var.task_memory
    container_port = tostring(var.container_port)
    image_tag      = var.image_tag
  }
}

# Simulated ECS Security Group
resource "null_resource" "ecs_sg" {
  triggers = {
    name         = "${var.project_name}-${var.environment}-ecs-sg"
    ingress_port = tostring(var.container_port)
  }
}

# Simulated ECS Service
resource "null_resource" "service" {
  triggers = {
    name          = "${var.project_name}-${var.environment}-service"
    desired_count = tostring(var.desired_count)
    launch_type   = "FARGATE"
  }
}
