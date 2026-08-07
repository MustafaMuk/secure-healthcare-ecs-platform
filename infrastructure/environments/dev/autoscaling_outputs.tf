output "ecs_autoscaling_resource_id" {
  description = "ECS service registered with Application Auto Scaling."
  value       = module.ecs_autoscaling.resource_id
}

output "ecs_autoscaling_minimum_capacity" {
  description = "Minimum development ECS task capacity."
  value       = module.ecs_autoscaling.minimum_capacity
}

output "ecs_autoscaling_maximum_capacity" {
  description = "Maximum development ECS task capacity."
  value       = module.ecs_autoscaling.maximum_capacity
}
