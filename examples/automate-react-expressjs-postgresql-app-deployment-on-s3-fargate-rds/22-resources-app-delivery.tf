#################
# CDN resources #
#################

resource "aws_cloudfront_origin_access_identity" "app_bucket_dist_oai" {
  comment  = "access-identity-${module.app_bucket.bucket.bucket_regional_domain_name}"
}

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    sid       = "PolicyForCloudFrontPrivateContent"
    actions   = ["s3:GetObject"]
    resources = ["${module.app_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app_bucket_dist_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app_bucket_policy" {
  bucket = module.app_bucket.bucket.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}

locals {
  app_bucket_origin_id = module.app_bucket.bucket.bucket_regional_domain_name
}

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "app_bucket_dist" {

  origin {
    origin_id   = local.app_bucket_origin_id
    domain_name = module.app_bucket.bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_bucket_dist_oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  aliases             = [var.app_domain_name]
  price_class         = "PriceClass_All"
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.app_bucket_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.app_bucket_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = "404"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
}

#############################
# SSL certificate resources #
#############################

resource "aws_acm_certificate" "app_bucket_cert" {
  provider = aws.global

  domain_name       = var.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "app_bucket_cert_validation" {
  provider = aws.global
  certificate_arn         = aws_acm_certificate.app_bucket_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_bucket_cert_validation : record.fqdn]
}

resource "aws_route53_record" "app_bucket_cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.app_bucket_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.app_zone.zone_id
  records         = [each.value.record]
  ttl             = 300
}

#################
# DNS resources #
#################

resource "aws_route53_record" "app_dns_record" {

  zone_id = data.aws_route53_zone.app_zone.zone_id
  name    = var.app_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app_bucket_dist.domain_name
    zone_id                = aws_cloudfront_distribution.app_bucket_dist.hosted_zone_id
    evaluate_target_health = false
  }

}
