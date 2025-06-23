# IAM Role for CodeDeploy
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

# AWS CodeDeploy Application
resource "aws_codedeploy_app" "web_app_codedeploy_app" {
  name             = "${var.project_name_prefix}-${var.environment_name}-app"
  compute_platform = "ECS"

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-codedeploy-app"
  }
}

# AWS CodeDeploy Deployment Group for Canary Deployment
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