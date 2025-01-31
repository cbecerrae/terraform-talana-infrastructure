# Terraform Infrastructure for Talana Attendance Marking

This repository provisions and manages the AWS infrastructure using **Terraform** to automate attendance marking in [Talana](https://peru.talana.com/es/remuneraciones/) using ECS tasks, EventBridge Scheduler, and CI/CD pipelines. The solution includes a variety of AWS resources for building, deploying, and managing the scraper bot, as well as scheduling its tasks and handling alerts.

## AWS Resources Provisioned

This Terraform configuration creates the following AWS resources:

- **ECR Repository** (`aws_ecr_repository.repository`): Stores the Docker images used by ECS tasks.
- **ECS Cluster** (`aws_ecs_cluster.scraper_cluster`): The cluster where ECS tasks run.
- **ECS Task Definition** (`aws_ecs_task_definition.scraper_task`): The task definition for the scraper bot container.
- **EventBridge Scheduler** (`module.eventbridge_scheduler[...]`): Schedules ECS tasks to run at specific intervals based on provided cron expressions.
- **IAM Roles**:
  - `aws_iam_role.scraper_codebuild_service_role`: CodeBuild service role.
  - `aws_iam_role.scraper_codepipeline_service_role`: CodePipeline service role.
  - `aws_iam_role.ecs_task_execution_role`: ECS task execution role.
  - `aws_iam_role.scraper_ecs_task_role`: ECS task role.
  - `aws_iam_role.eventbridge_scheduler_role`: Role for EventBridge Scheduler.
- **IAM Policies** (`aws_iam_role_policy[...]`): Policies attached to the IAM roles for ECS task execution, EventBridge scheduler, CodeBuild, and CodePipeline.
- **CodeBuild Project** (`aws_codebuild_project.scraper_build`): Builds the Docker image for the scraper bot.
- **CodePipeline** (`aws_codepipeline.scraper_pipeline`): Automates the CI/CD process for building and deploying the scraper bot.
- **SNS Topic** (`aws_sns_topic.main_topic`): For sending error alerts from ECS tasks.
- **SNS Subscription** (`aws_sns_topic_subscription.subscription`): Subscribed endpoint to receive error alerts.
- **S3 Buckets**:
  - `aws_s3_bucket.main_bucket`: Stores objects generated by ECS tasks.
  - `aws_s3_bucket.scraper_codepipeline_artifact_bucket`: Stores pipeline artifacts.
- **VPC and Networking**:
  - A VPC with public subnets (`module.vpc.aws_subnet.public[...]`).
  - Internet gateway (`module.vpc.aws_internet_gateway.this[0]`), route tables, and associations for public routing.
  - Security group (`aws_security_group.scraper_security_group`) for securing ECS task containers.

### Additional Resources

- **Availability Zones** (`data.aws_availability_zones.available`): Retrieves availability zones for resource placement.
- **Caller Identity** (`data.aws_caller_identity.current`): Retrieves the AWS account identity.
- **CodeStar Connection** (`aws_codestarconnections_connection.connection`): Establishes a connection between GitHub and AWS for CI/CD.

These resources work together to create a fully automated environment for marking attendance in Talana. The solution is designed for seamless integration with GitHub, enabling automatic image builds and deployments whenever changes are pushed to the `main` branch of the [Talana Scraper Bot repository](https://github.com/cbecerrae/talana-scraper-bot).

## Usage  

### 1. Clone the Repository 

```bash
git clone https://github.com/cbecerrae/terraform-talana-infrastructure.git
cd terraform-talana-infrastructure
```  

### 2. Initialize Terraform

Before running `terraform init`, make sure to configure the `cloud` block in the `terraform.tf` file with your **organization** and **workspace** information. Replace the values below with your actual organization and workspace details:

```hcl
cloud {
  organization = "your-organization-name"
  workspace    = "your-workspace-name"
}
```

Alternatively, you can **comment out** the `cloud` block if you prefer to run Terraform locally without HCP, or if you want to configure it later. Once configured, run the following command to initialize Terraform:

```bash
terraform init
```

### 3. Configure AWS Credentials 

Ensure your AWS credentials are properly configured using one of the following methods:  

- **AWS CLI**:  
   ```bash
   aws configure
   ```  
- **Environment variables**:  
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```  
- **HCP Terraform**:  
   If you're using HashiCorp Cloud Platform (HCP) Terraform, you should configure your AWS credentials as part of a variable set within the HCP platform to securely manage and store sensitive information like AWS access keys. Ensure you create and reference the appropriate variable set in HCP for your AWS credentials.

### 4. Configure Variables

Before setting up the variables in a `terraform.tfvars` file, carefully review the `variables.tf` file to customize optional variables and provide values for the required ones. 

Create a `terraform.tfvars` file to contain the values for the variables used in your Terraform configuration. Ensure that this file is placed in the root directory of your Terraform project.

### 5. Create and Import CodeStar Connection  

Create an **AWS CodeStar Connection** in your AWS account that has authorization to a fork of the [Talana Scraper Bot repository](https://github.com/cbecerrae/talana-scraper-bot). Once created, import it into your Terraform configuration:

```bash
terraform import aws_codestarconnections_connection.connection <codestar_connection_arn>
```  

Replace `<codestar_connection_arn>` with the actual **ARN** of the CodeStar Connection in AWS.  

### 6. Apply the Terraform Configuration 

```bash
terraform apply
```  

Review the plan and confirm the deployment by typing `yes` when prompted.  

## 7. Clean-up  

To remove the created resources, run the following Terraform command:  

```bash
terraform destroy
```  