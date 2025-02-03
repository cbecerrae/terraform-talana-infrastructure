resource "aws_codestarconnections_connection" "connection" {
  name          = var.aws_codestarconnections_connection_name
  provider_type = var.aws_codestarconnections_provider_type
  tags          = var.tags
}

resource "aws_codepipeline" "scraper_pipeline" {
  name           = "${var.project_name}-scraper-pipeline"
  role_arn       = aws_iam_role.scraper_codepipeline_service_role.arn
  pipeline_type  = "V2"
  execution_mode = "SUPERSEDED"
  tags           = var.tags

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = ["main"]
        }
        file_paths {
          excludes = ["**.md", ".github/**"]
        }
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.scraper_codepipeline_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.connection.arn
        FullRepositoryId = var.talana_scraper_bot_repository_id
        BranchName       = var.talana_scraper_bot_repository_branch
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
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.scraper_build.id
      }
    }
  }

}

resource "aws_s3_bucket" "scraper_codepipeline_artifact_bucket" {
  bucket        = "${var.project_name}-scraper-pipeline-artifact"
  force_destroy = "true"
  tags          = var.tags
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scraper_codepipeline_service_role" {
  name               = "${var.project_name}-scraper-codepipeline-service-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
  description        = "IAM role for the scraper CodePipeline project, granting permissions to CodeBuild, CodeStar Connections, and the S3 source artifact bucket."
  tags               = var.tags
}

resource "aws_iam_role_policy" "scraper_codepipeline_policy" {
  name = "AmazonCodePipelineServiceRolePolicy"
  role = aws_iam_role.scraper_codepipeline_service_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ],
        "Resource" : aws_codebuild_project.scraper_build.arn,
        "Effect" : "Allow"
      },
      {
        "Action" : "codestar-connections:UseConnection",
        "Resource" : aws_codestarconnections_connection.connection.arn,
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
        "Action" : [
          "s3:PutObjectAcl",
          "s3:PutObjectVersionAcl"
        ],
        "Resource" : "${aws_s3_bucket.scraper_codepipeline_artifact_bucket.arn}/*",
        "Effect" : "Allow"
      }
    ]
  })
}