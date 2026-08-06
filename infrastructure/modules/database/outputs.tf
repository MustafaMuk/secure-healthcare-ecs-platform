output "database_instance_id" {
  description = "Identifier of the CareFlow PostgreSQL instance."
  value       = aws_db_instance.this.identifier
}

output "database_address" {
  description = "Private DNS address of the PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "database_port" {
  description = "Port used by PostgreSQL."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial CareFlow database name."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the RDS master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}

output "database_subnet_group_name" {
  description = "RDS database subnet group."
  value       = aws_db_subnet_group.this.name
}
