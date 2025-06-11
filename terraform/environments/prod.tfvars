aws_region            = "eu-central-1"
project_name_prefix   = "MyWebApp"
environment_name      = "prod"
vpc_cidr            = "10.0.0.0/16"
private_subnets_cidrs = ["10.0.1.0/24", "10.0.2.0/24"] # -- private subnets
public_subnets_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"] # -- public subnets
availability_zones  = ["eu-central-1a", "eu-central-1b"] # Optional: if you want to be explicit

custom_tags = {
  Owner       = "OpsTeam"
  CostCenter  = "PROD456"
  Criticality = "High"
}