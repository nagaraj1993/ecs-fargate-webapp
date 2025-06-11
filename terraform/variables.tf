# # -----------
# # -- parameters
# # -- 
# # -- environmnet specific variables loaded from ../environments/<workspace>.tfvars 
# # ---------------

variable "aws_region" {
  description = "The AWS region for deployment."
  type        = string
  default     = "eu-central-1"
}

variable "project_name_prefix" {
  description = "A prefix for resource names (e.g., 'MyWebApp')."
  type        = string
}

variable "environment_name" {
  description = "The name of the environment (e.g., 'prod', 'non-prod'). This helps in tagging and naming."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnets_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnets_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "Explicit list of Availability Zones for the subnets. Should match the number of subnets."
  type        = list(string)
  default     = [] # Module will attempt to auto-assign if empty based on region
}

variable "custom_tags" {
  description = "Custom tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_name" {
  description = "Name of the dynamodb"
  type        = string
  default     = "my-awshandson-bucket-lock"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances. Override default in module if needed."
  type        = string
  default     = "ami-08aa372c213609089"
}

variable "github_pat" {
  description = "GitHub Personal Access Token for CodePipeline source."
  type        = string
  sensitive   = true
}