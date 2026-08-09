output "task_execution_role_arn" {
  description = "Simulated ARN of the ECS task execution role"
  value       = "arn:aws:iam::123456789012:role/${null_resource.ecs_task_execution_role.triggers.name}"
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = null_resource.ecs_task_execution_role.triggers.name
}

output "task_role_arn" {
  description = "Simulated ARN of the ECS task role"
  value       = "arn:aws:iam::123456789012:role/${null_resource.ecs_task_role.triggers.name}"
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = null_resource.ecs_task_role.triggers.name
}
