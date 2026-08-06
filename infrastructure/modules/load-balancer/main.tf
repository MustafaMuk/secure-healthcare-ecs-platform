locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_lb" "application" {
  name = "${local.name_prefix}-alb"

  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.load_balancer_security_group_id
  ]

  subnets = var.public_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
  enable_http2               = true
  idle_timeout               = 60
  ip_address_type            = "ipv4"

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-alb"
    Tier    = "public-load-balancer"
    Purpose = "Public entry point for CareFlow"
  })
}

resource "aws_lb_target_group" "application" {
  name = "${local.name_prefix}-api-tg"

  port        = var.application_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled = true

    protocol = "HTTP"
    port     = "traffic-port"
    path     = var.health_check_path
    matcher  = "200"

    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-api-target-group"
    Tier    = "private-application"
    Purpose = "CareFlow ECS task registration"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-http-listener"
  })
}
