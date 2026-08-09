output "repository_url" {
  description = "Simulated ECR repository URL"
  value       = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/${null_resource.ecr_repo.triggers.name}"
}

output "repository_arn" {
  description = "Simulated ECR repository ARN"
  value       = "arn:aws:ecr:eu-west-1:123456789012:repository/${null_resource.ecr_repo.triggers.name}"
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = null_resource.ecr_repo.triggers.name
}
