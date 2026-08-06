variable "application_image_tag" {
  description = "Immutable Git commit tag deployed from Amazon ECR."
  type        = string

  validation {
    condition = can(
      regex("^[0-9a-f]{40}$", var.application_image_tag)
    )

    error_message = "The application image tag must be a full Git SHA."
  }
}
