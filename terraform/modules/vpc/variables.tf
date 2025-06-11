variable "aws_region" {
  description = "The AWS region where VPC resources will be created."
  type        = string
}

variable "project_name" {
  description = "A base name for resources and tags within the VPC module (e.g., MyWebApp-prod-VPC)."
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of Availability Zones for the subnets. If empty, the module will attempt to pick them based on the region and subnet count."
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}