variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "github_subject" {
  description = "Exact GitHub Actions OIDC subject permitted to assume the deployment role."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository GitHub Actions may publish to."
  type        = string
}

variable "ecs_service_arn" {
  description = "Exact ECS service GitHub Actions may deploy."
  type        = string
}

variable "task_execution_role_arn" {
  description = "ECS execution role that may be passed to new task-definition revisions."
  type        = string
}

variable "task_role_arn" {
  description = "Application task role that may be passed to new task-definition revisions."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID."
  type        = string
}

variable "github_repository_owner_id" {
  description = "Immutable GitHub repository owner ID."
  type        = string
}

variable "github_ref" {
  description = "Git ref permitted to deploy."
  type        = string
}
