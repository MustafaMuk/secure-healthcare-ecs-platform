variable "aws_region" {
  description = "AWS region used by the CareFlow platform."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "This project must use the eu-west-2 region."
  }
}

variable "project_name" {
  description = "Name used for AWS resource identification."
  type        = string
  default     = "careflow"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}
