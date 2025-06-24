variable "project_name_prefix" {
  description = "A prefix for all resources to ensure uniqueness and identification."
  type        = string
}

variable "environment_name" {
  description = "The environment name (e.g., dev, non-prod, prod)."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where EFS and ECS resources will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs where EFS mount targets and ECS Fargate tasks will reside."
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "The ID of the security group used by your ECS Fargate tasks."
  type        = string
}