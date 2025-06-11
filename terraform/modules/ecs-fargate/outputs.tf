# modules/ecs-fargate/outputs.tf

output "ecs_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the ECS Cluster."
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository where Docker images will be pushed."
  value       = aws_ecr_repository.web_app.repository_url
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.web_app_alb.dns_name
}