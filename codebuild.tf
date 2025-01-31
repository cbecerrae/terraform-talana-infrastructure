resource "aws_codebuild_project" "scraper_build" {
  name         = "${var.project_name}-scraper-build"
  description  = "CodeBuild project responsible for building the scraper Docker image from the repository and pushing it to ECR."
  service_role = aws_iam_role.scraper_codebuild_service_role.arn
  tags         = var.tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "REPOSITORY_URI"
      type  = "PLAINTEXT"
      value = aws_ecr_repository.repository.repository_url
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${var.project_name}-scraper-build"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scraper_codebuild_service_role" {
  name               = "${var.project_name}-scraper-codebuild-service-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
  description        = "IAM role for the scraper CodeBuild project, granting permissions to CloudWatch Logs, the S3 source artifact bucket, and ECR."
  tags               = var.tags
}

resource "aws_iam_role_policy" "scraper_codebuild_policy" {
  name = "AmazonCodeBuildServiceRolePolicy"
  role = aws_iam_role.scraper_codebuild_service_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_codebuild_project.scraper_build.logs_config[0].cloudwatch_logs[0].group_name}",
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_codebuild_project.scraper_build.logs_config[0].cloudwatch_logs[0].group_name}:*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*",
          "s3:DeleteObject*",
          "s3:PutObject",
          "s3:PutObjectLegalHold",
          "s3:PutObjectRetention",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionTagging",
          "s3:Abort*"
        ],
        "Resource" : [
          aws_s3_bucket.scraper_codepipeline_artifact_bucket.arn,
          "${aws_s3_bucket.scraper_codepipeline_artifact_bucket.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        "Resource" : aws_ecr_repository.repository.arn,
        "Effect" : "Allow"
      }
    ]
  })
}