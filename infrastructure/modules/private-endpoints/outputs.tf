output "s3_endpoint_id" {
  description = "Gateway endpoint used for private S3 access."
  value       = aws_vpc_endpoint.s3.id
}

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs keyed by AWS service."
  value = {
    for name, endpoint in aws_vpc_endpoint.interface :
    name => endpoint.id
  }
}
