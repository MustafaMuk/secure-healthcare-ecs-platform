output "repository_name" {
  description = "Name of the CareFlow application ECR repository."
  value       = aws_ecr_repository.application.name
}

output "repository_url" {
  description = "URL used to push and pull CareFlow container images."
  value       = aws_ecr_repository.application.repository_url
}

output "repository_arn" {
  description = "ARN of the CareFlow application ECR repository."
  value       = aws_ecr_repository.application.arn
}
