output "oidc_provider_arn" {
  description = "AWS IAM OIDC provider used by GitHub Actions."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "deployment_role_arn" {
  description = "IAM role assumed by the GitHub Actions deployment workflow."
  value       = aws_iam_role.github_deploy.arn
}

output "trusted_github_subject" {
  description = "Exact GitHub OIDC subject trusted by AWS."
  value       = var.github_subject
}
