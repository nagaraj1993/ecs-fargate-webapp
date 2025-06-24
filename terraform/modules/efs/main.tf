# --- EFS File System ---
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.project_name_prefix}-${var.environment_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
//  kms_key_id       = "alias/aws/efs" # Using default EFS KMS key as requested

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-efs"
  }
}

# EFS Access Point
resource "aws_efs_access_point" "main" {
  file_system_id = aws_efs_file_system.main.id
  posix_user {
    uid = 1000 # User ID inside the container
    gid = 1000 # Group ID inside the container
  }
  root_directory {
    path = "/efs_data" # This path will be created on EFS if it doesn't exist
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755" # Example permissions for the root directory
    }
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-efs-access-point"
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name_prefix}-${var.environment_name}-efs-sg"
  description = "Allow NFS access to EFS from ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049 # NFS port
    to_port         = 2049
    protocol        = "tcp"
    # This allows inbound NFS traffic ONLY from your ECS Fargate tasks' security group
    security_groups = [var.ecs_tasks_security_group_id] # Reference to your existing ECS task SG
    description     = "Allow NFS from ECS Fargate Tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-efs-sg"
  }
}

# EFS Mount Targets
# Create a mount target in each private subnet where your ECS tasks might run.
resource "aws_efs_mount_target" "mount_targets" {
  for_each        = { for idx, subnet_id in var.private_subnet_ids : idx => subnet_id }
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}