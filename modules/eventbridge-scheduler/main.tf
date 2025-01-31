resource "aws_scheduler_schedule" "scheduler" {
  name        = "${var.project_name}-${var.schedule_name_suffix}"
  description = var.schedule_description

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = var.cluster_arn
    role_arn = var.scheduler_iam_role_arn
    input = jsonencode({
    "containerOverrides": [
        {
            "name": "${var.project_name}-scraper-container",
            "command": [
                "--type",
                var.mark_type,
                "--email",
                var.talana_credentials.user_email,
                "--password",
                var.talana_credentials.user_password
            ]
        }
    ]
    }
  )

    ecs_parameters {
      task_definition_arn = var.aws_ecs_task_definition_arn_without_revision
      launch_type         = "FARGATE"
      task_count = 1

      network_configuration {
        assign_public_ip = true
        security_groups  = [var.security_group_id]
        subnets          = var.subnet_ids
      }
    }
  }
}