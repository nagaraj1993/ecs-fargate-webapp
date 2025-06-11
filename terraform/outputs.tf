# Output the ECR Repository URL and ECS Cluster Name for easy access
output "ecr_repository_url" {
  description = "ECR Repository URL for the web app."
  value       = module.ecs_fargate.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster."
  value       = module.ecs_fargate.ecs_cluster_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.ecs_fargate.alb_dns_name
}