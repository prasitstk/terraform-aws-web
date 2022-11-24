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

variable "src_repo_url" {
  type        = string
  description = "Git source code repository URL"
  default     = "https://github.com/prasitstk/expressjs-hello-world.git"
}

variable "app_ctr_img_tag" {
  type        = string
  description = "Container image tag on the ECR image repository"
  default     = "latest"
}

variable "app_ctr_img_repo_name" {
  type        = string
  description = "ECR image repository name"
}

variable "app_vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "app_svc_fixed_task_count" {
  type        = number
  description = "Fixed number of desired task count for the ECS service"
  default     = 1
}
