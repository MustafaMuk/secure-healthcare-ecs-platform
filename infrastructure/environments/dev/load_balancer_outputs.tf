output "load_balancer_dns_name" {
  description = "Public DNS name of the development ALB."
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "ARN of the development ALB."
  value       = module.load_balancer.load_balancer_arn
}

output "application_target_group_arn" {
  description = "Target group used by the development ECS service."
  value       = module.load_balancer.target_group_arn
}

output "http_listener_arn" {
  description = "Initial development HTTP listener ARN."
  value       = module.load_balancer.http_listener_arn
}
