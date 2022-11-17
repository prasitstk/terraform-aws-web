###########
# Outputs #
###########

output "website_endpoint_url" {
  value = "http://${aws_s3_bucket_website_configuration.website_bucket_policy_website_cfg.website_endpoint}"
}
