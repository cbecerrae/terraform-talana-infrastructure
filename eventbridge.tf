module "eventbridge_scheduler" {
  source = "./modules/eventbridge-scheduler"

  for_each = { for index, schedule in var.mark_schedules : index => schedule }

  mark_type            = each.value.mark_type
  schedule_name_suffix = each.value.schedule_name_suffix
  schedule_expression  = each.value.schedule_expression
  schedule_description = each.value.schedule_description

  project_name                                 = var.project_name
  talana_credentials                           = var.talana_credentials
  scheduler_iam_role_arn                       = aws_iam_role.eventbridge_scheduler_role.arn
  subnet_ids                                   = module.vpc.public_subnets
  security_group_id                            = aws_security_group.scraper_security_group.id
  cluster_arn                                  = aws_ecs_cluster.scraper_cluster.arn
  aws_ecs_task_definition_arn_without_revision = aws_ecs_task_definition.scraper_task.arn_without_revision
  aws_ecs_container_name                       = aws_ecr_repository.repository.name
  schedule_expression_timezone                 = var.schedule_expression_timezone
}

data "aws_iam_policy_document" "eventbridge_scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_scheduler_role" {
  name               = "${var.project_name}-eventbridge-scheduler-service-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_scheduler_assume_role.json
  description        = "IAM role for the EventBridge Scheduler, granting permissions to ECS for triggering the ECS tasks."
  tags               = var.tags
}

resource "aws_iam_role_policy" "eventbridge_scheduler_policy" {
  name = "AmazonEventBridgeSchedulerServiceRolePolicy"
  role = aws_iam_role.eventbridge_scheduler_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:RunTask"
        ],
        "Resource" : [
          "arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${aws_ecs_task_definition.scraper_task.family}:*",
          "arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${aws_ecs_task_definition.scraper_task.family}"
        ],
        "Condition" : {
          "ArnLike" : {
            "ecs:cluster" : aws_ecs_cluster.scraper_cluster.arn
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
    }
  )
}
