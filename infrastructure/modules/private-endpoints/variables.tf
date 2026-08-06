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

variable "vpc_id" {
  description = "VPC containing the private endpoints."
  type        = string
}

variable "application_subnet_ids" {
  description = "Private application subnets containing ECS tasks."
  type        = list(string)

  validation {
    condition     = length(var.application_subnet_ids) == 2
    error_message = "Exactly two application subnets must be supplied."
  }
}

variable "application_route_table_ids" {
  description = "Route tables used by the private application subnets."
  type        = list(string)

  validation {
    condition     = length(var.application_route_table_ids) == 2
    error_message = "Exactly two application route tables must be supplied."
  }
}

variable "application_security_group_id" {
  description = "Security group used by ECS application tasks."
  type        = string
}

variable "endpoint_security_group_id" {
  description = "Security group attached to interface VPC endpoints."
  type        = string
}
