variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the platform."
  type        = string
}

variable "application_subnet_ids" {
  description = "Private subnets used by ECS Fargate tasks."
  type        = list(string)

  validation {
    condition     = length(var.application_subnet_ids) == 2
    error_message = "Exactly two application subnets must be supplied."
  }
}

variable "application_security_group_id" {
  description = "Security group attached to ECS tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group used by the ECS service."
  type        = string
}

variable "application_image_uri" {
  description = "Immutable ECR image URI including its digest."
  type        = string
}

variable "application_version" {
  description = "Git commit represented by the deployed image."
  type        = string
}

variable "database_host" {
  description = "Private RDS PostgreSQL hostname."
  type        = string
}

variable "database_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "database_secret_arn" {
  description = "RDS-managed secret containing username and password."
  type        = string
  sensitive   = true
}

variable "application_port" {
  description = "Port exposed by the CareFlow API."
  type        = number
  default     = 3000
}
