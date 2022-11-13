variable "bucket" {
  description = "Bucket name"
  type        = string
}

variable "force_destroy" {
  description = "Whether to do force deletion the bucket while there are still some objects exist"
  type        = bool
  default     = false
}

variable "acl" {
  description = "The canned ACL to apply to the bucket"
  type        = string
  default     = "private"
}

variable "logging" {
  description = "Server access logging configuration"
  type        = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}