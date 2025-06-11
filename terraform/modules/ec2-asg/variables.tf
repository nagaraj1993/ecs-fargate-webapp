variable "project_name" {
  description = "A name prefix for all resources to organize them (e.g., MyWebApp-non-prod)."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the EC2 instances and ASG will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs where the ASG instances will be launched."
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 1 # At least one private subnet needed
    error_message = "The 'private_subnet_ids' list must contain at least one subnet ID."
  }
}

variable "alb_target_group_arn" {
  description = "The ARN of the ALB Target Group to which instances will be registered."
  type        = string
}

variable "alb_sg_id" {
  description = "The ID of the ALB's Security Group, to allow ingress from ALB to instances."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the application servers."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances."
  type        = string
}

variable "asg_desired_capacity" {
  description = "The desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "The minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "The maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 3
}