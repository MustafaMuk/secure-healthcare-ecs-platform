variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the CareFlow platform."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster monitored by CloudWatch."
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service monitored by CloudWatch."
  type        = string
}

variable "database_instance_id" {
  description = "RDS database instance identifier."
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "Application Load Balancer ARN suffix used by CloudWatch."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ALB target-group ARN suffix used by CloudWatch."
  type        = string
}

variable "application_log_group_name" {
  description = "CloudWatch Logs group used by the CareFlow application."
  type        = string
}
