locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_sns_topic" "platform_alerts" {
  name         = "${local.name_prefix}-platform-alerts"
  display_name = "CareFlow Alerts"

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-platform-alerts"
    Purpose = "Operational monitoring notifications"
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name = "${local.name_prefix}-ecs-high-cpu"

  alarm_description = (
    "CareFlow ECS CPU utilization remained above 80 percent."
  )

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name = "${local.name_prefix}-ecs-high-memory"

  alarm_description = (
    "CareFlow ECS memory utilization remained above 80 percent."
  )

  namespace   = "AWS/ECS"
  metric_name = "MemoryUtilization"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_target" {
  alarm_name = "${local.name_prefix}-alb-unhealthy-target"

  alarm_description = (
    "The CareFlow load balancer detected an unhealthy ECS target."
  )

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name = "${local.name_prefix}-target-5xx-errors"

  alarm_description = "CareFlow targets returned at least five HTTP 5XX responses within five minutes."

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name = "${local.name_prefix}-rds-high-cpu"

  alarm_description = (
    "CareFlow PostgreSQL CPU utilization remained above 80 percent."
  )

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  dimensions = {
    DBInstanceIdentifier = var.database_instance_id
  }

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name = "${local.name_prefix}-rds-low-storage"

  alarm_description = (
    "CareFlow PostgreSQL free storage fell below 5 GiB."
  )

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  dimensions = {
    DBInstanceIdentifier = var.database_instance_id
  }

  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 5368709120
  comparison_operator = "LessThanThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_dashboard" "platform" {
  dashboard_name = "${local.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = join("\n", [
            "# CareFlow — Development Operations",
            "",
            "ECS Fargate → Application Load Balancer → Private RDS PostgreSQL",
            "",
            "**Environment:** ${var.environment} | **Region:** ${var.aws_region}"
          ])
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "ECS Fargate — CPU and Memory"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }

          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "CPU %"
                stat  = "Average"
              }
            ],
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "Memory %"
                stat  = "Average"
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "Application Load Balancer"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              {
                label = "Requests"
                stat  = "Sum"
              }
            ],
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Response time"
                stat  = "Average"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Target 5XX"
                stat  = "Sum"
              }
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Unhealthy targets"
                stat  = "Maximum"
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 24
        height = 6

        properties = {
          title   = "RDS PostgreSQL"
          region  = var.aws_region
          view    = "timeSeries"
          stacked = false
          period  = 300

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              var.database_instance_id,
              {
                label = "CPU %"
                stat  = "Average"
              }
            ],
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              var.database_instance_id,
              {
                label = "Connections"
                stat  = "Average"
              }
            ],
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              var.database_instance_id,
              {
                label = "Free storage bytes"
                stat  = "Average"
              }
            ]
          ]
        }
      },

      {
        type   = "log"
        x      = 0
        y      = 14
        width  = 24
        height = 8

        properties = {
          title  = "Recent CareFlow HTTP Requests"
          region = var.aws_region
          view   = "table"

          query = join(" ", [
            "SOURCE '${var.application_log_group_name}'",
            "| fields @timestamp, event, method, path, status_code, duration_ms, correlation_id",
            "| filter event = \"http_request\"",
            "| sort @timestamp desc",
            "| limit 50"
          ])
        }
      }
    ]
  })
}
