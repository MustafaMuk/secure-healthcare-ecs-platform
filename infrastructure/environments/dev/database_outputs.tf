output "database_instance_id" {
  description = "Development PostgreSQL instance identifier."
  value       = module.database.database_instance_id
}

output "database_address" {
  description = "Private DNS address of development PostgreSQL."
  value       = module.database.database_address
}

output "database_port" {
  description = "Development PostgreSQL port."
  value       = module.database.database_port
}

output "database_name" {
  description = "Development PostgreSQL database name."
  value       = module.database.database_name
}

output "database_master_secret_arn" {
  description = "Secret containing the PostgreSQL master credentials."
  value       = module.database.master_user_secret_arn
  sensitive   = true
}
