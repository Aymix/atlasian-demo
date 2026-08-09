################################################################################
# ALB Stack — SIMULATED
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

resource "random_id" "alb" {
  byte_length = 8
  keepers = {
    project = var.project_name
    env     = var.environment
  }
}

# Simulated ALB Security Group
resource "null_resource" "alb_sg" {
  triggers = {
    name        = "${var.project_name}-${var.environment}-alb-sg"
    ingress_80  = "0.0.0.0/0"
    ingress_443 = "0.0.0.0/0"
  }
}

# Simulated Application Load Balancer
resource "null_resource" "alb" {
  triggers = {
    name = "${var.project_name}-${var.environment}-alb"
    type = "application"
  }
}

# Simulated Target Group
resource "null_resource" "target_group" {
  triggers = {
    name        = "${var.project_name}-${var.environment}-tg"
    port        = tostring(var.container_port)
    target_type = "ip"
    health_path = var.health_check_path
  }
}

# Simulated Listener
resource "null_resource" "listener" {
  triggers = {
    port     = "80"
    protocol = "HTTP"
    action   = "forward"
  }
}
