output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = null_resource.cluster.triggers.name
}

output "cluster_arn" {
  description = "Simulated ARN of the ECS cluster"
  value       = "arn:aws:ecs:eu-west-1:123456789012:cluster/${null_resource.cluster.triggers.name}"
}

output "service_name" {
  description = "Name of the ECS service"
  value       = null_resource.service.triggers.name
}

output "task_definition_arn" {
  description = "Simulated task definition ARN"
  value       = "arn:aws:ecs:eu-west-1:123456789012:task-definition/${null_resource.task_definition.triggers.family}:1"
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = null_resource.log_group.triggers.name
}
