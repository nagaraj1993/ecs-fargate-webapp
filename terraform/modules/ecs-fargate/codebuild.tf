# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name_prefix}-${var.environment_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codebuild-role"
  }
}

# IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name_prefix}-${var.environment_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Permissions for CodeBuild to put logs to CloudWatch
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${local.codebuild_log_group_name}",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${local.codebuild_log_group_name}:*"
        ]
      },
      # Permissions for CodeBuild to read from S3 for source (if S3 source was used)
      # and write build artifacts to S3 (CodePipeline artifacts bucket)
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket" # Added ListBucket for CodePipeline artifact bucket
        ],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      # Permissions for CodeBuild to pull/push images to ECR
      {
        Effect   = "Allow",
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*" # Change this to "*" for all ECR actions to resolve potential resource scoping issues
      },
      # Permissions for CodeBuild to assume service roles (if needed for other actions)
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          # Add any other ECS actions your CodeBuild role needs (e.g., ecs:RegisterTaskDefinition if you were doing that, but you're not)
        ]
        Resource = "*" # Or limit to specific task definition ARNs if desired for stricter security
      }
    ]
  })
}

# AWS CodeBuild Project
resource "aws_codebuild_project" "app_build" {
  name          = "${var.project_name_prefix}-${var.environment_name}-app-build"
  description   = "Builds Docker image and pushes to ECR"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "10" # minutes (increased slightly from 5 for robustness)

  artifacts {
    type = "CODEPIPELINE" # This project will output artifacts for CodePipeline
    # name = "BuildArtifact" # Optional, CodePipeline will manage artifact names
  }

  cache {
    type  = "S3"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_CUSTOM_CACHE"]
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL" # Or MEDIUM/LARGE depending on needs
    image                       = "aws/codebuild/standard:7.0" # Use a recent standard image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required for Docker builds
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.web_app.repository_url
    }
    environment_variable {
      name  = "ECS_TASK_DEFINITION_NAME"
      value = aws_ecs_task_definition.web_app_task.family # Name of your task definition family
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "${var.project_name_prefix}-${var.environment_name}-webapp" # Matches container_name in task definition
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = aws_ecs_service.web_app_service.name
    }
  }

  source {
    type            = "CODEPIPELINE" # Source comes from CodePipeline
    buildspec       = "buildspec.yml" # We'll create this file in your app repo
  }

  # Log to CloudWatch Logs
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name_prefix}-${var.environment_name}-app-build"
      stream_name = "build-log-stream"
    }
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-app-build"
  }
}