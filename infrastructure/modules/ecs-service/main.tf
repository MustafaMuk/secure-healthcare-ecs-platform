locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  container_name = "careflow-api"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid     = "AllowECSTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-cluster"
    Purpose = "CareFlow Fargate workloads"
  })
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/ecs/${local.name_prefix}/careflow-api"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-application-logs"
    Purpose = "CareFlow ECS application logs"
  })
}

resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = (
    data.aws_iam_policy_document.ecs_tasks_assume_role.json
  )

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-ecs-execution-role"
    Purpose = "ECS image logging and secret retrieval"
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role = aws_iam_role.execution.name

  policy_arn = (
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  )
}

data "aws_iam_policy_document" "execution_secrets" {
  statement {
    sid    = "ReadDatabaseCredentials"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.database_secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "${local.name_prefix}-read-database-secret"
  role = aws_iam_role.execution.id

  policy = (
    data.aws_iam_policy_document.execution_secrets.json
  )
}

resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = (
    data.aws_iam_policy_document.ecs_tasks_assume_role.json
  )

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-ecs-task-role"
    Purpose = "Runtime role with no AWS API permissions"
  })
}

resource "aws_ecs_task_definition" "application" {
  family = "${local.name_prefix}-careflow-api"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.application_image_uri
      essential = true
      user      = "1000:1000"

      readonlyRootFilesystem = true

      mountPoints    = []
      systemControls = []
      volumesFrom    = []

      portMappings = [
        {
          name          = "http"
          containerPort = var.application_port
          hostPort      = var.application_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = tostring(var.application_port)
        },
        {
          name  = "APP_VERSION"
          value = var.application_version
        },
        {
          name  = "DB_HOST"
          value = var.database_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.database_port)
        },
        {
          name  = "DB_NAME"
          value = var.database_name
        },
        {
          name  = "DB_SSL"
          value = "true"
        },
        {
          name  = "DB_SSL_CA_PATH"
          value = "/app/certs/global-bundle.pem"
        }
      ]

      secrets = [
        {
          name = "DB_USER"

          valueFrom = (
            "${var.database_secret_arn}:username::"
          )
        },
        {
          name = "DB_PASSWORD"

          valueFrom = (
            "${var.database_secret_arn}:password::"
          )
        }
      ]

      linuxParameters = {
        initProcessEnabled = true

        capabilities = {
          add  = []
          drop = ["ALL"]
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "node -e \"fetch('http://127.0.0.1:3000/health/ready').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))\""
        ]

        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      stopTimeout = 30

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "application"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-careflow-api"
    Service = "CareFlow API"
  })
}

resource "aws_ecs_service" "application" {
  name    = "${local.name_prefix}-careflow-api"
  cluster = aws_ecs_cluster.this.id

  task_definition = (
    aws_ecs_task_definition.application.arn
  )

  desired_count = 0

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets = var.application_subnet_ids

    security_groups = [
      var.application_security_group_id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.container_name
    container_port   = var.application_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    aws_iam_role_policy.execution_secrets
  ]

  lifecycle {
    # Allows later CLI or autoscaling changes without Terraform
    # resetting the running-task count to zero.
    ignore_changes = [
      desired_count
    ]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-careflow-api"
    Service = "CareFlow API"
    Tier    = "private-application"
  })
}
