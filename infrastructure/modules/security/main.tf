locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

# AWS-managed list of CloudFront origin-facing IPv4 addresses.
# AWS maintains this list automatically.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Controls public traffic reaching the CareFlow ALB."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
    Tier = "public-load-balancer"
  })
}

resource "aws_security_group" "application" {
  name_prefix = "${local.name_prefix}-application-"
  description = "Controls traffic reaching CareFlow ECS tasks."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-sg"
    Tier = "private-application"
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-database-"
  description = "Controls traffic reaching CareFlow PostgreSQL."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-sg"
    Tier = "isolated-database"
  })
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.name_prefix}-endpoints-"
  description = "Controls private HTTPS access to AWS VPC endpoints."
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-endpoints-sg"
    Tier = "private-service-endpoints"
  })
}


resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.load_balancer.id

  description = "Permit HTTP origin traffic only from CloudFront."

  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol    = "tcp"
  from_port      = 80
  to_port        = 80

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudfront-to-alb"
  })
}

resource "aws_vpc_security_group_egress_rule" "alb_to_application" {
  security_group_id = aws_security_group.load_balancer.id

  description = "Permit the ALB to reach ECS application tasks."

  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = var.application_port
  to_port                      = var.application_port

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-to-application"
  })
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id = aws_security_group.application.id

  description = "Permit application traffic only from the ALB."

  referenced_security_group_id = aws_security_group.load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = var.application_port
  to_port                      = var.application_port

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-from-alb"
  })
}

resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  security_group_id = aws_security_group.application.id

  description = "Permit ECS tasks to reach PostgreSQL."

  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = var.database_port
  to_port                      = var.database_port

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-to-database"
  })
}

resource "aws_vpc_security_group_ingress_rule" "database_from_application" {
  security_group_id = aws_security_group.database.id

  description = "Permit PostgreSQL traffic only from ECS tasks."

  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = var.database_port
  to_port                      = var.database_port

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-from-application"
  })
}

resource "aws_vpc_security_group_egress_rule" "application_to_endpoints" {
  security_group_id = aws_security_group.application.id

  description = "Permit private HTTPS access to AWS service endpoints."

  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-to-endpoints"
  })
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_application" {
  security_group_id = aws_security_group.vpc_endpoints.id

  description = "Permit HTTPS endpoint access only from ECS tasks."

  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-endpoints-from-application"
  })
}
