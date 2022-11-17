output "app_cf_url" {
  value = "https://${aws_cloudfront_distribution.app_bucket_dist.domain_name}"
}

output "app_api_url" {
  value = "${aws_api_gateway_stage.app_rest_api_stage.invoke_url}"
}
