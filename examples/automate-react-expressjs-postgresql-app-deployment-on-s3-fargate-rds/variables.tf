#############
# Variables #
#############

variable "aws_region" {
  type        = string
  description = "AWS Region for the created resources"
}

variable "aws_access_key" {
  type        = string
  description = "AWS Access Key of your AWS account for the created resources"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key of your AWS account for the created resources"
}

variable "sys_name" {
  type        = string
  description = "System name used to naming various components of this system"
}

variable "sys_vpc_cidr_block" {
  type        = string
  description = "System VPC CIDR block in a specified aws_region (it should be in between /16 to /24)"
}

variable "app_zone_name" {
  type        = string
  description = "Application hosted zone name. It can be the domain name registered outside Amazon Route 53."
}

variable "app_domain_name" {
  type        = string
  description = "Application domain name"
}

variable "app_codestar_connection_arn" {
  type        = string
  description = "AWS CodeStar connection ARN of the application source codes to be deployed"
}

variable "app_full_repository_id" {
  type        = string
  description = "Full repository ID/path of the source code of the application"
}

variable "app_branch_name" {
  type        = string
  description = "Branch name of the repository of the source code of the application"
}

variable "api_zone_name" {
  type        = string
  description = "API hosted zone name. It can be the domain name registered outside Amazon Route 53."
}

variable "api_domain_name" {
  type        = string
  description = "API domain name"
}

variable "api_src_repo_url" {
  type        = string
  description = "Git source code repository URL for API"
  default     = "https://github.com/prasitstk/node-express-sequelize-postgresql.git"
}

variable "api_ctr_img_tag" {
  type        = string
  description = "Container image tag on the ECR image repository for API"
  default     = "latest"
}

variable "api_ctr_img_repo_name" {
  type        = string
  description = "ECR image repository name for API"
}

variable "api_svc_fixed_task_count" {
  type        = number
  description = "Fixed number of desired task count for the ECS service for API"
  default     = 1
}

variable "api_cfg_port" {
  type        = number
  description = "API backend port"
  default     = 8080
}

variable "api_codestar_connection_arn" {
  type        = string
  description = "AWS CodeStar connection ARN of the API source codes to be deployed"
}

variable "api_full_repository_id" {
  type        = string
  description = "Full repository ID/path of the source code of the API"
}

variable "api_branch_name" {
  type        = string
  description = "Branch name of the repository of the source code of the API"
}

variable "data_db_name" {
  type        = string
  description = "Database name"
}

variable "data_master_db_password" {
  type        = string
  description = "Master user password of the database"
}
