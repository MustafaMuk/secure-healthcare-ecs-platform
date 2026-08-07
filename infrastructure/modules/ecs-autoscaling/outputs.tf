output "resource_id" {
  description = "Application Auto Scaling ECS resource identifier."
  value       = aws_appautoscaling_target.ecs_service.resource_id
}

output "minimum_capacity" {
  description = "Minimum ECS service task capacity."
  value       = aws_appautoscaling_target.ecs_service.min_capacity
}

output "maximum_capacity" {
  description = "Maximum ECS service task capacity."
  value       = aws_appautoscaling_target.ecs_service.max_capacity
}

output "cpu_policy_arn" {
  description = "CPU target-tracking scaling policy ARN."
  value       = aws_appautoscaling_policy.cpu.arn
}

output "memory_policy_arn" {
  description = "Memory target-tracking scaling policy ARN."
  value       = aws_appautoscaling_policy.memory.arn
}
