resource "aws_ecr_registry_scanning_configuration" "careflow" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"

    repository_filter {
      filter = "${var.project_name}/${var.environment}/*"

      filter_type = "WILDCARD"
    }
  }
}
