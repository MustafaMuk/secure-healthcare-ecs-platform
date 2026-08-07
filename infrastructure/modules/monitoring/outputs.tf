output "dashboard_name" {
  description = "CloudWatch operations dashboard name."
  value       = aws_cloudwatch_dashboard.platform.dashboard_name
}

output "alerts_topic_arn" {
  description = "SNS topic receiving CareFlow operational alarms."
  value       = aws_sns_topic.platform_alerts.arn
}

output "alarm_names" {
  description = "CloudWatch alarms protecting the CareFlow platform."

  value = [
    aws_cloudwatch_metric_alarm.ecs_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_target.alarm_name,
    aws_cloudwatch_metric_alarm.alb_target_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name
  ]
}
