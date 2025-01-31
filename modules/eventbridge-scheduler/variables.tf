variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "talana_credentials" {
  description = "Credentials to pass to the ECS task"
  type        = map(string)
  sensitive = true
}

variable "scheduler_iam_role_arn" {
  description = "ARN of the IAM role for the scheduler"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS cluster"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ECS cluster"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "aws_ecs_task_definition_arn_without_revision" {
  description = "ARN of the ECS task definition without the revision"
  type        = string
}

variable "aws_ecs_container_name" {
  description = "Name of the ECS container"
  type        = string
}

variable "schedule_name_suffix" {
  description = "Suffix for the schedule name"
  type        = string
}

variable "schedule_expression" {
  description = "Cron expression for the schedule"
  type        = string
}

variable "schedule_expression_timezone" {
  description = "Timezone for the schedule expression"
  type        = string
}

variable "schedule_description" {
  description = "Description for the schedule"
  type        = string
}

variable "mark_type" {
  description = "Type of attendance mark"
  type        = string
}
