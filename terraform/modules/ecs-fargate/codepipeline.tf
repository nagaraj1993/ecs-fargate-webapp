# IAM Role for CodePipeline
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

# ecsTaskExecutionRole. This name must exactly match the role name in taskdef.json ARN
resource "aws_iam_role" "ecs_task_execution_role_ecsdeploy" {
  name = "ecsTaskExecutionRole" # This name must match what's in your taskdef.json

  # This is the trust policy that fixes your error.
  # It allows the ECS Tasks service to assume this role.
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
    Name = "${var.project_name_prefix}-${var.environment_name}-ecs-task-execution-role"
  }
}

# Attach the standard AWS-managed policy to the role.
# This policy grants the necessary permissions for ECR and CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role_ecsdeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name_prefix}-${var.environment_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ... [your other statements for S3 and CodeBuild remain unchanged] ...
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ],
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:GetProject"
        ],
        Resource = aws_codebuild_project.app_build.arn
      },
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeployments",
          "codedeploy:StopDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentTarget"
        ],
        Resource = [
          aws_codedeploy_app.web_app_codedeploy_app.arn,
          aws_codedeploy_deployment_group.web_app_dg.arn,
          "arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:CodeDeployDefault.ECSAllAtOnce"
        ]
      },
      # --- ADD THIS NEW BLOCK FOR ECS PERMISSIONS ---
      {
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition"
        ],
        Resource = "*"
      },
      # --- END OF NEW BLOCK ---
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = data.aws_secretsmanager_secret.github_token_data.arn
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = [
          aws_iam_role.codebuild_role.arn,
          aws_iam_role.codedeploy_role.arn,
          aws_iam_role.ecs_task_execution_role_ecsdeploy.arn 
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/MyWebApp-non-prod-webapp-task"

  # Best practice: Set a retention period to manage log storage costs.
  # This will delete logs older than 7 days. Adjust as needed.
  retention_in_days = 7

  tags = {
    Name = "MyWebApp-non-prod-ecs-log-group"
  }
}

# AWS CodePipeline

## Creation for the first time
# resource "aws_secretsmanager_secret" "github_token" {
#   name = "${var.project_name_prefix}-${var.environment_name}-github-token"
# }

# resource "aws_secretsmanager_secret_version" "github_token_value" {
#   secret_id     = aws_secretsmanager_secret.github_token.id
#   secret_string = var.github_pat
# }

# Data source to retrieve the GitHub Token secret by its name
data "aws_secretsmanager_secret" "github_token_data" {
  # Use the same naming convention you used for the resource to retrieve it
  name = "${var.project_name_prefix}-${var.environment_name}-github-token"
}

# Data source to retrieve the actual secret string from the latest version
data "aws_secretsmanager_secret_version" "github_token_value_data" {
  # Reference the ID or ARN of the secret retrieved by the previous data source
  secret_id = data.aws_secretsmanager_secret.github_token_data.id
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
        OAuthToken = data.aws_secretsmanager_secret_version.github_token_value_data.secret_string
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
      provider        = "CodeDeployToECS"
      # The action needs both sets of artifacts to work
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      
      configuration = {
        ApplicationName                = aws_codedeploy_app.web_app_codedeploy_app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.web_app_dg.deployment_group_name
        
        # This tells CodeDeploy to find taskdef.json in the SOURCE artifact. This fixes the error.
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath = "taskdef.json"
        # This tells CodeDeploy to find appspec.yml in the SOURCE artifact.
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath = "appspec.yaml"
        # Point this to the BuildArtifact created by CodeBuild
        Image1ArtifactName             = "BuildArtifact"
        # This tells CodeDeploy WHICH container to update (must match names in appspec/taskdef)
        Image1ContainerName            = "IMAGE1_NAME" #"${var.project_name_prefix}-${var.environment_name}-webapp"
      }
    }
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-pipeline"
  }
}