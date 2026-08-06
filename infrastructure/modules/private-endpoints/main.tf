locals {
  name_prefix = "${var.project_name}-${var.environment}"

  interface_services = {
    ecr_api        = "ecr.api"
    ecr_dkr        = "ecr.dkr"
    logs           = "logs"
    secretsmanager = "secretsmanager"
  }

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = var.vpc_id

  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.application_route_table_ids

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-s3-endpoint"
    Purpose = "Private ECR image-layer access"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id = var.vpc_id

  service_name = (
    "com.amazonaws.${var.aws_region}.${each.value}"
  )

  vpc_endpoint_type = "Interface"

  subnet_ids = var.application_subnet_ids

  security_group_ids = [
    var.endpoint_security_group_id
  ]

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${replace(each.key, "_", "-")}-endpoint"
  })
}

resource "aws_vpc_security_group_egress_rule" "application_to_s3" {
  security_group_id = var.application_security_group_id

  description = "Permit ECS tasks to download ECR image layers from S3."

  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-to-s3"
  })
}
