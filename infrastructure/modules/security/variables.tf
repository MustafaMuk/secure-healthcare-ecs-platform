variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC containing the security groups."
  type        = string
}

variable "application_port" {
  description = "Port exposed by the CareFlow application."
  type        = number
  default     = 3000

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535
    )

    error_message = "Application port must be between 1 and 65535."
  }
}

variable "database_port" {
  description = "PostgreSQL database port."
  type        = number
  default     = 5432

  validation {
    condition = (
      var.database_port >= 1 &&
      var.database_port <= 65535
    )

    error_message = "Database port must be between 1 and 65535."
  }
}
