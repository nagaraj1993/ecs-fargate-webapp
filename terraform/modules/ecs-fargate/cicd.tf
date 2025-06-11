locals {
  codebuild_log_group_name = "/aws/codebuild/${var.project_name_prefix}-${var.environment_name}-app-build"
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# 1. S3 Bucket for CodePipeline Artifacts
# CodePipeline needs an S3 bucket to store artifacts between stages
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = lower("${var.project_name_prefix}-${var.environment_name}-codepipeline-artifacts-${data.aws_caller_identity.current.account_id}")

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codepipeline-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 2. IAM Role for CodeBuild
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
        Resource = aws_ecr_repository.web_app.arn # Grant permissions to your specific ECR repo
      },
      # Permissions for CodeBuild to assume service roles (if needed for other actions)
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "*"
      }
    ]
  })
}

# 3. AWS CodeBuild Project
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

# 4. IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project_name_prefix}-${var.environment_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codedeploy-role"
  }
}

# IAM Policy Attachment for CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_role.name
}

# 5. AWS CodeDeploy Application
resource "aws_codedeploy_app" "web_app_codedeploy_app" {
  name             = "${var.project_name_prefix}-${var.environment_name}-app"
  compute_platform = "ECS"

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codedeploy-app"
  }
}

# 6. AWS CodeDeploy Deployment Group for Canary Deployment
resource "aws_codedeploy_deployment_group" "web_app_dg" {
  app_name              = aws_codedeploy_app.web_app_codedeploy_app.name
  deployment_group_name = "${var.project_name_prefix}-${var.environment_name}-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  # Use a deployment configuration suitable for ECS Blue/Green. CodeDeployDefault.ECSLinear10PercentEvery1Minute is not preferred by Pro model.
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  # CORRECTED BLOCK NAME:
  blue_green_deployment_config { # Renamed from blue_green_deployment_configuration
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.web_app_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http_listener.arn]
      }

    #   # test_traffic_route is optional but useful for running tests before shifting production traffic.
    #   # If you don't have a separate test listener, you can remove this block.
    #   test_traffic_route {
    #     listener_arns = [aws_lb_listener.http_listener_test.arn] # Assuming you have a test listener
    #   }

      target_group {
        name = aws_lb_target_group.web_app_tg_blue.name
      }
      target_group {
        name = aws_lb_target_group.web_app_tg_green.name
      }
    }
  }

  # This block is needed to handle rollbacks correctly
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codedeploy-dg"
  }
}

# 7. IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name_prefix}-${var.environment_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codepipeline-role"
  }
}

# IAM Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name_prefix}-${var.environment_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Permissions for CodePipeline to access S3 for artifacts
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      # Permissions for CodePipeline to invoke CodeBuild
      {
        Effect   = "Allow",
        Action   = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:GetProject"
        ],
        Resource = aws_codebuild_project.app_build.arn
      },
      # Permissions for CodePipeline to invoke CodeDeploy
      {
        Effect   = "Allow",
        Action   = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeployments",
          "codedeploy:StopDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentTarget"
        ],
        Resource = [
          aws_codedeploy_app.web_app_codedeploy_app.arn,
          aws_codedeploy_deployment_group.web_app_dg.arn
        ]
      },
      # Permissions for CodePipeline to retrieve the GitHub OAuth token from Secrets Manager
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.github_token.arn # Grant access to this specific secret
      },
      # Allow CodePipeline to pass roles to other services
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = [
          aws_iam_role.codebuild_role.arn,
          aws_iam_role.codedeploy_role.arn
        ]
      }
    ]
  })
}

# 9. AWS CodePipeline

resource "aws_secretsmanager_secret" "github_token" {
  name = "${var.project_name_prefix}-${var.environment_name}-github-token"
}

resource "aws_secretsmanager_secret_version" "github_token_value" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_pat
}

resource "aws_codepipeline" "web_app_pipeline" {
  name     = "${var.project_name_prefix}-${var.environment_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        Owner      = "nagaraj1993" # Just your username/org
        Repo       = "ecs-fargate-webapp" # Just the repo name
        Branch     = "main"
        OAuthToken = aws_secretsmanager_secret_version.github_token_value.secret_string
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {
        ApplicationName     = aws_codedeploy_app.web_app_codedeploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web_app_dg.deployment_group_name
      }
    }
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-pipeline"
  }
}