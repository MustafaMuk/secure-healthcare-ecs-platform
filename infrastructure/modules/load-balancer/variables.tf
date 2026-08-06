variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC containing the load balancer and its targets."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets used by the internet-facing ALB."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) == 2
    error_message = "Exactly two public subnets must be supplied."
  }
}

variable "load_balancer_security_group_id" {
  description = "Security group attached to the Application Load Balancer."
  type        = string
}

variable "application_port" {
  description = "Port exposed by the CareFlow application."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Application readiness endpoint used by the target group."
  type        = string
  default     = "/health/ready"
}
