output "load_balancer_arn" {
  description = "ARN of the CareFlow Application Load Balancer."
  value       = aws_lb.application.arn
}

output "load_balancer_dns_name" {
  description = "Public DNS name assigned to the Application Load Balancer."
  value       = aws_lb.application.dns_name
}

output "load_balancer_zone_id" {
  description = "Route 53 hosted-zone ID of the Application Load Balancer."
  value       = aws_lb.application.zone_id
}

output "target_group_arn" {
  description = "Target group used by the CareFlow ECS service."
  value       = aws_lb_target_group.application.arn
}

output "http_listener_arn" {
  description = "ARN of the initial HTTP listener."
  value       = aws_lb_listener.http.arn
}
