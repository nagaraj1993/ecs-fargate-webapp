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

variable "container_mount_path" {
  description = "The path inside the container where the EFS volume will be mounted."
  type        = string
  default     = "/app/data" # Adjust this default path to your application's needs
}

variable "efs_file_system_id" {
  description = "The ID of the EFS File System to attach to ECS tasks."
  type        = string
}

variable "efs_access_point_id" {
  description = "The ID of the EFS Access Point to use for ECS tasks."
  type        = string
}

variable "efs_security_group_id" {
  description = "The ID of the EFS Security Group to allow egress to from ECS tasks."
  type        = string
}