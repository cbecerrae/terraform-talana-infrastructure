variable "aws_region" {
  description = "AWS region in which to provision infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-talana-automation"
}

variable "tags" {
  description = "Tags for AWS resources"
  type        = map(string)
}

variable "subscription_email" {
  description = "Email to subscribe to the SNS topic"
  type        = string
}

variable "mark_schedules" {
  description = "Schedules to trigger the ECS tasks"
  type = list(object({
    mark_type            = string
    schedule_name_suffix = string
    schedule_expression  = string
    schedule_description = string
  }))
  default = [
    {
      mark_type            = "In"
      schedule_name_suffix = "in-scheduler"
      schedule_expression  = "cron(40 7 ? * 2-6 *)"
      schedule_description = "Scheduler that triggers the ECS tasks with an 'In' Attendance Mark from Monday to Friday at 7:40 AM Lima time (UTC-5)."
    },
    {
      mark_type            = "Out"
      schedule_name_suffix = "out-scheduler"
      schedule_expression  = "cron(0 19 ? * 2-5 *)"
      schedule_description = "Scheduler that triggers the ECS tasks with an 'Out' Attendance Mark from Monday to Thursday at 7:00 PM Lima time (UTC-5)."
    },
    {
      mark_type            = "Out"
      schedule_name_suffix = "out-friday-scheduler"
      schedule_expression  = "cron(0 17 ? * 6 *)"
      schedule_description = "Scheduler that triggers the ECS tasks with an 'Out' Attendance Mark on Fridays at 5:00 PM Lima time (UTC-5)."
    }
  ]

  validation {
    condition     = alltrue([for schedule in var.mark_schedules : schedule.mark_type == "In" || schedule.mark_type == "Out"])
    error_message = "mark_type must be either 'In' or 'Out'."
  }

  validation {
    condition     = alltrue([for schedule in var.mark_schedules : can(regex("^cron\\(.*\\)$", schedule.schedule_expression))])
    error_message = "schedule_expression must start with 'cron(' and end with ')'."
  }
}

variable "schedule_expression_timezone" {
  description = "Timezone for the schedule expression"
  type        = string
  default     = "America/Lima"
}

variable "talana_credentials" {
  description = "Talana credentials to pass to the ECS task"
  type = object({
    user_email    = string
    user_password = string
  })
  sensitive = true
}

variable "aws_codestarconnections_connection_name" {
  description = "Connection name of the AWS CodeStar Connections connection"
  type        = string
}

variable "aws_codestarconnections_provider_type" {
  description = "Provider type for the AWS CodeStar Connections connection"
  type        = string
  default     = "GitHub"
}

variable "talana_scraper_bot_repository_id" {
  description = "ID of the Talana Scraper Bot repository authorized in the AWS CodeStar Connections connection. Expected format: 'owner/repository_name'"
  type        = string
}

variable "talana_scraper_bot_repository_branch" {
  description = "Branch of the Talana Scraper Bot repository authorized in the AWS CodeStar Connections connection"
  type        = string
  default     = "main"
}