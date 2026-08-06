output "cluster_name" {
  description = "Name of the CareFlow ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the CareFlow ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Name of the CareFlow ECS service."
  value       = aws_ecs_service.application.name
}

output "task_definition_arn" {
  description = "ARN of the CareFlow task definition."
  value       = aws_ecs_task_definition.application.arn
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the application task role."
  value       = aws_iam_role.task.arn
}

output "application_log_group_name" {
  description = "CloudWatch log group used by the application."
  value       = aws_cloudwatch_log_group.application.name
}
