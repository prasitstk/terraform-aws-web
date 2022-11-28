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

variable "sys_zone_name" {
  type        = string
  description = "Route 53 hosted zone name. It can be the domain name registered outside Amazon Route 53."
}

variable "sys_name" {
  type        = string
  description = "System name"
  default     = "sys"
}

variable "sys_api_stage_name" {
  type        = string
  description = "API Gateway staged name for deployed REST API."
  default     = "test"
}

variable "app1_name" {
  type        = string
  description = "App-1 name on S3 bucket."
  default     = "app1"
}

variable "app2_name" {
  type        = string
  description = "App-2 name on S3 bucket."
  default     = "app2" 
}

variable "api1_name" {
  type        = string
  description = "API-1 name on API Gateway REST API."
  default     = "api1"  
}

variable "api2_name" {
  type        = string
  description = "API-2 name on API Gateway REST API."
  default     = "api2"   
}
