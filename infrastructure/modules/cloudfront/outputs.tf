output "distribution_id" {
  description = "ID of the CareFlow CloudFront distribution."
  value       = aws_cloudfront_distribution.application.id
}

output "distribution_arn" {
  description = "ARN of the CareFlow CloudFront distribution."
  value       = aws_cloudfront_distribution.application.arn
}

output "domain_name" {
  description = "HTTPS CloudFront domain name for CareFlow."
  value       = aws_cloudfront_distribution.application.domain_name
}
