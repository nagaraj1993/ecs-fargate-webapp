module "vpc" {
  source = "./modules/vpc" # Path to your local VPC module

  aws_region           = var.aws_region
  project_name         = "${var.project_name_prefix}-${var.environment_name}" # e.g., MyWebApp-non-prod
  vpc_cidr_block       = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnets_cidrs
  private_subnet_cidrs = var.private_subnets_cidrs
  availability_zones   = var.availability_zones # Pass through, module handles default if empty

  common_tags = merge(
    {
      Project     = var.project_name_prefix
      Environment = var.environment_name
    },
    var.custom_tags
  )
}

# module "ec2_app" {
#   source = "./modules/ec2-asg" # Path to your new EC2-ASG module

#   project_name          = "${var.project_name_prefix}-${var.environment_name}"
#   vpc_id                = module.vpc.vpc_id
#   private_subnet_ids    = module.vpc.private_subnet_ids # Pass output from VPC module
#   alb_target_group_arn  = module.alb.alb_target_group_arn # Pass output from ALB module
#   alb_sg_id             = module.alb.alb_security_group_id # Pass output from ALB module

#   instance_type         = "t3.micro"
#   ami_id                = var.ami_id # You can explicitly set this in root variables or let the module use the data source

#   asg_desired_capacity  = 2
#   asg_min_size          = 1
#   asg_max_size          = 3
# }

# module "alb" {
#   source = "./modules/alb" # Path to your local VPC module
#   project_name        = "${var.project_name_prefix}-${var.environment_name}" # e.g., MyWebApp-non-prod
#   vpc_id = module.vpc.vpc_id
#   public_subnet_ids = module.vpc.public_subnet_ids
# //  instance_security_group_id = module.ec2_app.instance_security_group_id
# }

# Module for ECS Fargate resources
module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  project_name_prefix = var.project_name_prefix
  environment_name    = var.environment_name
  vpc_id              = module.vpc.vpc_id
  aws_region          = var.aws_region
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  github_pat = var.github_pat
}