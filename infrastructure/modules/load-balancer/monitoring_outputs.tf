output "load_balancer_arn_suffix" {
  description = "ARN suffix used by CloudWatch ALB metrics."
  value       = aws_lb.application.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix used by CloudWatch target-group metrics."
  value       = aws_lb_target_group.application.arn_suffix
}
