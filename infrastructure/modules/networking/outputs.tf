output "vpc_id" {
  description = "ID of the CareFlow VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block assigned to the CareFlow VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability Zones used by the platform."
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer."
  value       = aws_subnet.public[*].id
}

output "application_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  value       = aws_subnet.application[*].id
}

output "database_subnet_ids" {
  description = "Isolated subnet IDs for RDS."
  value       = aws_subnet.database[*].id
}

output "application_route_table_ids" {
  description = "Route-table IDs for private application subnets."
  value       = aws_route_table.application[*].id
}

output "database_route_table_ids" {
  description = "Route-table IDs for isolated database subnets."
  value       = aws_route_table.database[*].id
}
