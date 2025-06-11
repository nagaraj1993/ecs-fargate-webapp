output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main_alb.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.main_alb.arn
}

output "alb_target_group_arn" {
  description = "The ARN of the web application target group."
  value       = aws_lb_target_group.web_app_tg.arn
}

output "alb_security_group_id" {
  description = "The ID of the ALB's security group."
  value       = aws_security_group.alb_sg.id
}