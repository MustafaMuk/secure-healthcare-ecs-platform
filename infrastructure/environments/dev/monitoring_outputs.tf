output "cloudwatch_dashboard_name" {
  description = "CareFlow CloudWatch operations dashboard."
  value       = module.monitoring.dashboard_name
}

output "platform_alerts_topic_arn" {
  description = "SNS topic receiving platform alarms."
  value       = module.monitoring.alerts_topic_arn
}

output "platform_alarm_names" {
  description = "CareFlow operational CloudWatch alarms."
  value       = module.monitoring.alarm_names
}
