variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster containing the scalable service."
  type        = string
}

variable "service_name" {
  description = "ECS service managed by Application Auto Scaling."
  type        = string
}

variable "minimum_capacity" {
  description = "Minimum number of ECS tasks."
  type        = number
  default     = 1

  validation {
    condition     = var.minimum_capacity >= 1
    error_message = "Minimum capacity must be at least one task."
  }
}

variable "maximum_capacity" {
  description = "Maximum number of ECS tasks."
  type        = number
  default     = 2

  validation {
    condition     = var.maximum_capacity >= 2
    error_message = "Maximum capacity must be at least two tasks."
  }
}

variable "cpu_target" {
  description = "Target average ECS CPU utilization percentage."
  type        = number
  default     = 60

  validation {
    condition = (
      var.cpu_target > 0 &&
      var.cpu_target <= 100
    )

    error_message = "CPU target must be between 1 and 100."
  }
}

variable "memory_target" {
  description = "Target average ECS memory utilization percentage."
  type        = number
  default     = 70

  validation {
    condition = (
      var.memory_target > 0 &&
      var.memory_target <= 100
    )

    error_message = "Memory target must be between 1 and 100."
  }
}
