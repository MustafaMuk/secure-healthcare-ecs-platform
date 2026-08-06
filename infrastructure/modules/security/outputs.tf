output "load_balancer_security_group_id" {
  description = "Security group used by the Application Load Balancer."
  value       = aws_security_group.load_balancer.id
}

output "application_security_group_id" {
  description = "Security group used by ECS Fargate tasks."
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "Security group used by RDS PostgreSQL."
  value       = aws_security_group.database.id
}

output "vpc_endpoint_security_group_id" {
  description = "Security group used by interface VPC endpoints."
  value       = aws_security_group.vpc_endpoints.id
}
