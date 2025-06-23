# AWS ECR to store Docker images
resource "aws_ecr_repository" "web_app" {
  name                 = "${lower(var.project_name_prefix)}-${var.environment_name}-webapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name_prefix}-${var.environment_name}-webapp-ecr"
  }
}

# AWS ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "web_app_policy" {
  repository = aws_ecr_repository.web_app.name
  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 10 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}