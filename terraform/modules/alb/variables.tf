variable "project_name" {
  description = "A base name for resources and tags within the VPC module (e.g., MyWebApp-prod-VPC)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from VPC Module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

# variable "instance_security_group_id" {
#   description = "The ID of the ALB's Security Group, to allow ingress from ALB to instances."
#   type        = string
# }