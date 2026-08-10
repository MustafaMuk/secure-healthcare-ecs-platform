output "cloudfront_distribution_id" {
  description = "Development CloudFront distribution ID."
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "Public HTTPS hostname for CareFlow."
  value       = module.cloudfront.domain_name
}

output "cloudfront_https_url" {
  description = "Public HTTPS URL for CareFlow."
  value       = "https://${module.cloudfront.domain_name}"
}
