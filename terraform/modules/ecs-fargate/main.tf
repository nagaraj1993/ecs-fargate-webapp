# AWS ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name_prefix}-${var.environment_name}-ecs-cluster"

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-ecs-cluster"
  }
}

# # IAM Role for ECS Task Execution
# # This role is assumed by the ECS agent to run tasks (e.g., pull images, send logs).
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name_prefix = "${var.project_name_prefix}-${var.environment_name}-ecs-task-execution-"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = {
#     Name = "${var.project_name_prefix}-${var.environment_name}-ecs-task-execution-role"
#   }
# }

# # Attach the managed policy for ECS Task Execution Role
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# 5. IAM Role for ECS Task (Application Role)
# This role is assumed by the application running inside the container.
# Add more specific permissions here if your app needs to interact with other AWS services (e.g., S3, DynamoDB). See the commented section.
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name_prefix}-${var.environment_name}-ecs-task-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-ecs-task-app-role"
  }
}

# # -- ecs execution role
# data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
#   version = "2012-10-17"

#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ecs_task" {
#   name               = format("%s-ecs-task-%s", local.resource_prefix, local.resource_suffix)
#   assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
# }

# resource "aws_iam_role_policy" "iam_ecs_task_role_policy" {
#   name   = format("%s-ecs-%s", local.resource_prefix, local.resource_suffix)
#   role   = aws_iam_role.ecs_task.name
#   policy = data.aws_iam_policy_document.ecs_task_policy.json
# }

# data "aws_iam_policy_document" "ecs_task_policy" {
#   statement {
#     actions = [
#       "s3:ListBucket"
#     ]
#     resources = [
#       aws_s3_bucket.public_storage_bucket.arn,
#       aws_s3_bucket.private_storage_bucket.arn,
#       aws_s3_bucket.frontend_bucket.arn,
#       aws_s3_bucket.backup_data_storage.arn
#     ]
#   }

#   statement {
#     actions = [
#       "s3:Get*",
#       "s3:Put*",
#       "s3:DeleteObject*"
#     ]
#     resources = concat(
#       [
#         format("%s/*", aws_s3_bucket.public_storage_bucket.arn),
#         format("%s/*", aws_s3_bucket.private_storage_bucket.arn)
#       ]
#     )
#   }

#   statement {
#     actions = [
#       "s3:Get*",
#       "s3:Put*"
#     ]
#     resources = concat(
#       [
#         format("%s/*", aws_s3_bucket.backup_data_storage.arn)
#       ]
#     )
#   }

#   statement {
#     actions = [
#       "s3:Get*"
#     ]
#     resources = concat(
#       [
#         format("%s/*", aws_s3_bucket.frontend_bucket.arn)
#       ]
#     )
#   }

#   statement {
#     actions = [
#       "s3:ListAllMyBuckets",
#       "s3:GetBucketLocation",
#       "s3:CreateBucket"
#     ]
#     resources = [
#       "arn:aws:s3:::*"
#     ]
#   }

#   statement {
#     actions = [
#       "ssmmessages:CreateControlChannel",
#       "ssmmessages:CreateDataChannel",
#       "ssmmessages:OpenControlChannel",
#       "ssmmessages:OpenDataChannel"
#     ]
#     resources = [
#       "*"
#     ]
#   }

#   statement {
#     actions = [
#       "ssm:GetParameter",
#       "ssm:PutParameter"
#     ]
#     resources = [
#       format("arn:aws:ssm:%s:%s:parameter/*", local.aws_region, local.account_id)
#     ]
#   }

#   statement {
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:DescribeKey"
#     ]
#     resources = [
#       aws_kms_key.backend_rds_key.arn,
#       aws_kms_key.storage_bucket_key.arn,
#       aws_kms_key.parameter_store_key.arn
#     ]
#   }

#   statement {
#     actions = [
#       "rds:*"
#     ]
#     resources = [
#       aws_rds_cluster.backend_rds_aurora3.arn,
#       aws_rds_cluster.backend_rds.arn
#     ]
#   }

#   statement {
#     actions = [
#       "rds:DescribeDBClusters",
#       "rds:DescribeDBInstances",
#       "rds:DescribeDBClusterSnapshots"
#     ]
#     resources = [
#       "*"
#     ]
#   }

#   statement {
#     actions = [
#       "rds-db:connect"
#     ]
#     resources = [
#       format("arn:aws:rds-db:%s:%s:dbuser:%s/%s", local.aws_region, local.account_id, aws_rds_cluster.backend_rds_aurora3.cluster_resource_id, local.csp_db_admin),
#       format("arn:aws:rds-db:%s:%s:dbuser:%s/%s", local.aws_region, local.account_id, aws_rds_cluster.backend_rds.cluster_resource_id, local.csp_db_admin)
#     ]
#   }

#   statement {
#     actions = [
#       "ses:SendRawEmail"
#     ]
#     resources = [
#       "*"
#     ]
#   }

#   statement {
#     actions = [
#       "sts:AssumeRole",
#       "sts:SetSourceIdentity",
#       "sts:TagSession"
#     ]
#     resources = [
#       aws_iam_role.iam_datasync_role.arn
#     ]
#   }

#   statement {
#     actions = [
#       "secretsmanager:GetSecretValue"
#     ]
#     resources = [
#       local.ikos_shared_secret
#     ]
#   }

#   statement {
#     actions = [
#       "kms:GenerateDataKey",
#       "kms:Decrypt"
#     ]
#     resources = [
#       local.ikos_shared_secret_kms_key
#     ]
#   }
# }

# ECS Task Definition
# This defines your containerized application (its image, resources, ports, etc.).
resource "aws_ecs_task_definition" "web_app_task" {
  family                   = "${var.project_name_prefix}-${var.environment_name}-webapp-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    # 256 CPU units = 0.25 vCPU
  memory                   = "512"    # 512 MiB memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_ecsdeploy.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Assign the application role

  # --- EFS Volume Configuration ---
  volume {
    name = "${var.project_name_prefix}-${var.environment_name}-efs-volume"
    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      # Added: root_directory.
      # Note: If an access_point_id is specified, this value is often ignored by ECS
      # as the root directory is defined directly on the EFS Access Point itself.
      root_directory          = "/" // the root directory must either be set to "/" or be omitted.
      transit_encryption      = "ENABLED"
      # Added: transit_encryption_port. Default is 2049 if not specified.
      transit_encryption_port = 2049 # Standard NFS port for TLS
      # access_point_id and iam are directly under efs_volume_configuration,
      # not nested in an authorization_config block, per Terraform's syntax.
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }  

  # Container definition in JSON format
  container_definitions = jsonencode([
    {
      name      = "${var.project_name_prefix}-${var.environment_name}-webapp"
      image     = "${aws_ecr_repository.web_app.repository_url}:latest" # We'll push 'latest' for now
      essential = true # If true, the task stops if this container stops
      portMappings = [
        {
          containerPort = 3000 # Your Node.js app listens on port 3000
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/fargate/${var.project_name_prefix}-${var.environment_name}-webapp"
          "awslogs-region"        = var.aws_region # Assuming you have this variable. Add if not.
          "awslogs-stream-prefix" = "ecs"
        }
      },
      mountPoints = [
        {
          # This 'sourceVolume' MUST match the 'name' given in the 'volume' block above
          sourceVolume  = "${var.project_name_prefix}-${var.environment_name}-efs-volume",
          # This is the path inside your Docker container where EFS will be mounted
          containerPath = var.container_mount_path # You should define this variable in your project's variables.tf
          readOnly      = false                   # Set to true if container should not write to EFS
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-webapp-task"
  }
}

# CloudWatch Log Group for ECS Task Definition
# This ensures that logs from your Fargate tasks are sent to CloudWatch.
resource "aws_cloudwatch_log_group" "webapp_log_group" {
  name              = "/ecs/fargate/${var.project_name_prefix}-${var.environment_name}-webapp"
  retention_in_days = 7 # Adjust as needed

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-webapp-logs"
  }
}

# ALB Security Group
# Allows inbound HTTP traffic to the ALB.
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name_prefix}-${var.environment_name}-alb-sg-"
  description = "Allow HTTP access to ALB"
  vpc_id      = var.vpc_id # Use the vpc_id passed to the module

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere (for testing)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-alb-sg"
  }
}

# ECS Fargate Task Security Group
# Allows inbound traffic from the ALB, and all outbound traffic.
resource "aws_security_group" "ecs_tasks_sg" {
  name_prefix = "${var.project_name_prefix}-${var.environment_name}-ecs-tasks-sg-"
  description = "Allow HTTP from ALB and all outbound for ECS tasks"
  vpc_id      = var.vpc_id

  # Inbound rule: Allow traffic from the ALB's security group on container port 3000
  ingress {
    from_port       = 3000 # Your Node.js app's listening port
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # It is managed below
  # Outbound rule: Allow all outbound traffic (e.g., to fetch data, log, etc.)
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-ecs-tasks-sg"
  }
}

resource "aws_security_group_rule" "ecs_tasks_all_outbound_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # Represents all protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_tasks_sg.id
  description       = "Allow all outbound traffic from ECS tasks"
}

# Your existing EFS egress rule (no changes needed here)
resource "aws_security_group_rule" "ecs_tasks_to_efs_egress" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  source_security_group_id = var.efs_security_group_id
  description              = "Allow outbound NFS to EFS"
}

# Application Load Balancer (ALB)
resource "aws_lb" "web_app_alb" {
  name               = "${var.project_name_prefix}-${var.environment_name}-alb"
  internal           = false # Publicly accessible ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # ALB typically goes in public subnets

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-alb"
  }
}

# ALB Target Group
# Targets are the Fargate tasks running your web app.
resource "aws_lb_target_group" "web_app_tg_blue" {
  name        = "${var.project_name_prefix}-${var.environment_name}-tg"
  port        = 3000 # The port on the container/task (your Node.js app's port)
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate's awsvpc network mode

  health_check {
    protocol            = "HTTP"
    path                = "/" # Your app should respond to a GET request on /
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-299" # HTTP success codes
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-tg-blue"
  }
}

resource "aws_lb_target_group" "web_app_tg_green" {
  name        = "${var.project_name_prefix}-${var.environment_name}-tg-green" # New TG
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-tg-green"
  }
}

# ALB Listener
# Forwards HTTP traffic from ALB to the target group.
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg_blue.arn
  }

  lifecycle {
    ignore_changes = [
      default_action,
    ]
  }
}

# ECS Service
# Deploys and manages your Fargate tasks.
resource "aws_ecs_service" "web_app_service" {
  name                  = "${var.project_name_prefix}-${var.environment_name}-service"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.web_app_task.arn
  desired_count         = 1 # Initial count. CodeDeploy and/or auto-scaling will manage this later.
  launch_type           = "FARGATE"
  #platform_version = "LATEST"
  health_check_grace_period_seconds = 60
  enable_execute_command = true

  # This tells the service that CodeDeploy will manage its deployments.
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # Initial load balancer configuration. Terraform sets this once.
  load_balancer {
    target_group_arn = aws_lb_target_group.web_app_tg_blue.arn # Point to blue initially
    container_name   = "${var.project_name_prefix}-${var.environment_name}-webapp"
    container_port   = 3000
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  # --- THIS IS THE FIX ---
  # Tell Terraform to create the service with these values but never
  # try to change them back if an external process (like CodeDeploy)
  # updates them.
  lifecycle {
    ignore_changes = [
      task_definition, # CodeDeploy updates this with new revisions.
      load_balancer,   # CodeDeploy swaps target groups during blue/green.
      desired_count   # CodeDeploy manages the task count during deployments.
    ]
  }
  # ----------------------

  # Ensure the service waits for dependencies to be ready.
  depends_on = [
    aws_lb_listener.http_listener,
    aws_iam_role_policy_attachment.codedeploy_ecs_policy
  ]

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-service"
  }
}

resource "aws_iam_policy" "ecs_task_ssm_exec_policy" {
  name        = "${var.project_name_prefix}-${var.environment_name}-ecs-task-ssm-exec-policy"
  description = "Policy for ECS Task Role to allow SSM Session Manager for Execute Command"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:SignalSession" # Added for completeness
        ],
        Resource = "*" # Consider scoping this down to specific session ARNs in production
      },
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      # Optional: Permissions for session logging to S3 (uncomment if you enable session logging)
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "s3:PutObject",
      #     "s3:GetEncryptionConfiguration"
      #   ],
      #   Resource = "arn:aws:s3:::<your-ssm-session-log-bucket-name>/*"
      # },
      # Optional: Permissions for session logging to CloudWatch Logs (uncomment if you enable session logging)
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "logs:CreateLogGroup",
      #     "logs:CreateLogStream",
      #     "logs:PutLogEvents",
      #     "logs:DescribeLogStreams"
      #   ],
      #   Resource = "arn:aws:logs:*:*:log-group:/aws/ecs/containerinsights:*" # Or specific log group
      # }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ssm_exec_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_ssm_exec_policy.arn
}