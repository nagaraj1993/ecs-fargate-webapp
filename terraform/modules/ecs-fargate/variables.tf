variable "project_name_prefix" {
  description = "The prefix for all resources, e.g., 'mywebapp'."
  type        = string
}

variable "environment_name" {
  description = "The environment name, e.g., 'non-prod', 'prod'."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC. (While not directly used by cluster/repo, good to pass for consistency or future resources)."
  type        = string
}

variable "aws_region" { 
  description = "The AWS region where resources are deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ECS Fargate tasks."
  type        = list(string)
}

variable "github_pat" {
  description = "GitHub Personal Access Token for CodePipeline source."
  type        = string
  sensitive   = true
}