#####################
# Storage resources #
#####################

module "app_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "${var.app_domain_name}"
  force_destroy = true
  acl           = "private"
}
