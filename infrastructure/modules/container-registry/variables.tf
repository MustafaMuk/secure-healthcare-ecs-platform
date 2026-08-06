variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "force_delete" {
  description = "Allow Terraform to delete a non-empty development repository."
  type        = bool
  default     = false
}

variable "retained_image_count" {
  description = "Number of recent tagged images retained in ECR."
  type        = number
  default     = 15

  validation {
    condition     = var.retained_image_count >= 5
    error_message = "At least five recent images must be retained."
  }
}
