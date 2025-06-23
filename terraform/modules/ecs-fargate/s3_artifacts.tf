# S3 Bucket for CodePipeline Artifacts
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