output "ecr_repository_name" {
  description = "Name of the development ECR repository."
  value       = module.container_registry.repository_name
}

output "ecr_repository_url" {
  description = "URL of the development ECR repository."
  value       = module.container_registry.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the development ECR repository."
  value       = module.container_registry.repository_arn
}
