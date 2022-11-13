output "app_cf_url" {
  value = "https://${aws_cloudfront_distribution.app_bucket_dist.domain_name}"
}
