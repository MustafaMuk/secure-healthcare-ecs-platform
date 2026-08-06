output "load_balancer_security_group_id" {
  description = "Security group used by the development ALB."
  value       = module.security.load_balancer_security_group_id
}

output "application_security_group_id" {
  description = "Security group used by development ECS tasks."
  value       = module.security.application_security_group_id
}

output "database_security_group_id" {
  description = "Security group used by development RDS."
  value       = module.security.database_security_group_id
}

output "vpc_endpoint_security_group_id" {
  description = "Security group used by development VPC endpoints."
  value       = module.security.vpc_endpoint_security_group_id
}
