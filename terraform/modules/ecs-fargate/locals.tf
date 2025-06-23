locals {
  codebuild_log_group_name = "/aws/codebuild/${var.project_name_prefix}-${var.environment_name}-app-build"
}