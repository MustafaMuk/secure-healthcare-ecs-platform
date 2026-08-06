output "vpc_id" {
  description = "ID of the development VPC."
  value       = module.networking.vpc_id
}

output "availability_zones" {
  description = "Availability Zones used by the development environment."
  value       = module.networking.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "application_subnet_ids" {
  description = "Private ECS application subnet IDs."
  value       = module.networking.application_subnet_ids
}

output "database_subnet_ids" {
  description = "Isolated RDS database subnet IDs."
  value       = module.networking.database_subnet_ids
}
