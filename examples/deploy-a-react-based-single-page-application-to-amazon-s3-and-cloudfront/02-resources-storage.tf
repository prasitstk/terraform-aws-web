#####################
# Storage resources #
#####################

module "log_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "react-cors-spa-${aws_api_gateway_rest_api.app_rest_api.id}-logs"
  force_destroy = true
  acl           = "log-delivery-write"
}

module "app_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "react-cors-spa-${aws_api_gateway_rest_api.app_rest_api.id}"
  force_destroy = true
  acl           = "private"
  
  logging = {
    target_bucket = module.log_bucket.bucket.id
    target_prefix = "s3-access-logs/"
  }
}
