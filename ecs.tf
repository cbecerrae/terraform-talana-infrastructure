resource "aws_ecr_repository" "repository" {
  name                 = "${var.project_name}-scraper-repository"
  image_tag_mutability = "MUTABLE"
  force_delete         = "true"
  tags                 = var.tags
}

resource "aws_ecs_cluster" "scraper_cluster" {
  name = "${var.project_name}-scraper-cluster"
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "scraper_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.scraper_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

resource "aws_ecs_task_definition" "scraper_task" {
  family                   = "${var.project_name}-scraper-task"
  task_role_arn            = aws_iam_role.scraper_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  tags                     = var.tags

  container_definitions = jsonencode(
    [
      {
        "name" : "${var.project_name}-scraper-container"
        "image" : aws_ecr_repository.repository.repository_url,
        "essential" : true,
        "environment" : [
          { "name" : "SNS_TOPIC_ARN", "value" : aws_sns_topic.main_topic.arn },
          { "name" : "S3_BUCKET_NAME", "value" : aws_s3_bucket.main_bucket.id },
          { "name" : "AWS_REGION", "value" : var.aws_region }
        ],
        "logConfiguration" = {
          "logDriver" = "awslogs"
          "options" = {
            "awslogs-group" : "/aws/ecs/${var.project_name}-scraper-task"
            "awslogs-create-group" : "true",
            "awslogs-stream-prefix" : "ecs",
            "awslogs-region" : "us-east-1"
          }
        },

      }
    ]
  )
}

resource "aws_security_group" "scraper_security_group" {
  name        = "${var.project_name}-scraper-sg"
  description = "Security group for the scraper ECS tasks.  Allows only outbound traffic; no inbound traffic is permitted."
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scraper_ecs_task_role" {
  name               = "${var.project_name}-scraper-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  description        = "IAM role for the scraper ECS task, granting permissions to the main S3 bucket and the main SNS topic."
  tags               = var.tags
}

resource "aws_iam_role_policy" "scraper_ecs_task_policy" {
  name = "AmazonECSTaskRolePolicy"
  role = aws_iam_role.scraper_ecs_task_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.main_bucket.arn}/*",
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : aws_sns_topic.main_topic.arn
      }
    ]
    }
  )
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  description        = "IAM role for the ECS task execution, granting permissions to the ECS task for CloudWatch Logs."
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
    }
  )
}