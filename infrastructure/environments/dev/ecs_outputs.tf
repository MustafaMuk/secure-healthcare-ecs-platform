output "ecs_cluster_name" {
  description = "Development ECS cluster name."
  value       = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  description = "Development ECS service name."
  value       = module.ecs_service.service_name
}

output "ecs_task_definition_arn" {
  description = "Development ECS task definition ARN."
  value       = module.ecs_service.task_definition_arn
}

output "ecs_application_log_group" {
  description = "Development application log group."
  value       = module.ecs_service.application_log_group_name
}

output "deployed_application_image_tag" {
  description = "Git commit represented by the ECS release."
  value       = var.application_image_tag
}
