variable "aws_region" {
  description = "AWS region used by the CareFlow platform."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "This project must use the eu-west-2 region."
  }
}
