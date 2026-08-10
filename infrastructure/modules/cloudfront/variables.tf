variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "origin_domain_name" {
  description = "DNS name of the CareFlow Application Load Balancer."
  type        = string
}
