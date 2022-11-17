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

variable "website_bucket_name" {
  type        = string
  description = "S3 bucket name for the website asset. It needs to be globally unique."
}

variable "aws_codestar_connection_arn" {
  type        = string
  description = "AWS CodeStart connection ARN of source codes to be deployed"
}

variable "full_repository_id" {
  type        = string
  description = "Full repository ID/path of the source code of the static website"
}

variable "branch_name" {
  type        = string
  description = "Branch name of the repository of the source code of the static website"
}
