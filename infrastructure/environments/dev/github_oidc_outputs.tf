output "github_actions_deployment_role_arn" {
  description = "OIDC role assumed by GitHub Actions."
  value       = module.github_oidc.deployment_role_arn
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions AWS OIDC provider."
  value       = module.github_oidc.oidc_provider_arn
}

output "github_actions_trusted_subject" {
  description = "Exact GitHub identity trusted by AWS."
  value       = module.github_oidc.trusted_github_subject
}
