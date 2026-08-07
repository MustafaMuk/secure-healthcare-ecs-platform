locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_appautoscaling_target" "ecs_service" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"

  resource_id = (
    "service/${var.cluster_name}/${var.service_name}"
  )

  min_capacity = var.minimum_capacity
  max_capacity = var.maximum_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name = "${local.name_prefix}-ecs-cpu-target-tracking"

  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = (
        "ECSServiceAverageCPUUtilization"
      )
    }

    target_value = var.cpu_target

    scale_out_cooldown = 60
    scale_in_cooldown  = 180
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name = "${local.name_prefix}-ecs-memory-target-tracking"

  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = (
        "ECSServiceAverageMemoryUtilization"
      )
    }

    target_value = var.memory_target

    scale_out_cooldown = 60
    scale_in_cooldown  = 180
  }
}
