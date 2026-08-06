output "s3_vpc_endpoint_id" {
  description = "Development S3 gateway endpoint ID."
  value       = module.private_endpoints.s3_endpoint_id
}

output "interface_vpc_endpoint_ids" {
  description = "Development interface endpoint IDs."
  value       = module.private_endpoints.interface_endpoint_ids
}
