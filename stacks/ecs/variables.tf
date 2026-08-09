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

variable "task_cpu" {
  description = "CPU units for the Fargate task (1 vCPU = 1024)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = string
  default     = "512"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}
