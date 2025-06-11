aws_region            = "eu-central-1"
project_name_prefix   = "MyWebApp"
environment_name      = "non-prod"
vpc_cidr            = "10.1.0.0/16"
private_subnets_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnets_cidrs  = ["10.1.3.0/24", "10.1.4.0/24"]
availability_zones  = ["eu-central-1a", "eu-central-1b"] # Optional: if you want to be explicit

custom_tags = {
  Owner       = "DevTeam"
  CostCenter  = "DEV123"
}