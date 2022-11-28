####################
# Module variables #
####################

locals {
  sys_domain_name = "${var.sys_name}.${var.sys_zone_name}"
  app1_bucket_origin_id = module.app1_bucket.bucket.bucket_regional_domain_name
  app2_bucket_origin_id = module.app2_bucket.bucket.bucket_regional_domain_name
  api_origin_id         = replace(aws_api_gateway_deployment.sys_rest_api_deployment.invoke_url, "/^https?://([^/]*).*/", "$1")
}

#################
# CDN resources #
#################

#--------------------#
# app1 bucket origin #
#--------------------#

resource "aws_cloudfront_origin_access_identity" "app1_bucket_dist_oai" {
  comment  = "access-identity-${module.app1_bucket.bucket.bucket_regional_domain_name}"
}

data "aws_iam_policy_document" "app1_bucket_policy" {
  statement {
    sid       = "PolicyForCloudFrontPrivateContent"
    actions   = ["s3:GetObject"]
    resources = ["${module.app1_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app1_bucket_dist_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app1_bucket_policy" {
  bucket = module.app1_bucket.bucket.id
  policy = data.aws_iam_policy_document.app1_bucket_policy.json
}

#--------------------#
# app2 bucket origin #
#--------------------#

resource "aws_cloudfront_origin_access_identity" "app2_bucket_dist_oai" {
  comment  = "access-identity-${module.app2_bucket.bucket.bucket_regional_domain_name}"
}

data "aws_iam_policy_document" "app2_bucket_policy" {
  statement {
    sid       = "PolicyForCloudFrontPrivateContent"
    actions   = ["s3:GetObject"]
    resources = ["${module.app2_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app2_bucket_dist_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app2_bucket_policy" {
  bucket = module.app2_bucket.bucket.id
  policy = data.aws_iam_policy_document.app2_bucket_policy.json
}

#-------------------------#
# CloudFront distribution #
#-------------------------#

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "sys_dist" {

  origin {
    origin_id   = local.app1_bucket_origin_id
    domain_name = module.app1_bucket.bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app1_bucket_dist_oai.cloudfront_access_identity_path
    }
  }
  
  origin {
    origin_id   = local.app2_bucket_origin_id
    domain_name = module.app2_bucket.bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app2_bucket_dist_oai.cloudfront_access_identity_path
    }
  }
  
  origin {
  	domain_name = "${local.api_origin_id}"
  	origin_id   = "${local.api_origin_id}"
  	origin_path = "/${aws_api_gateway_stage.sys_rest_api_stage.stage_name}"
  
  	custom_origin_config {
  		http_port              = 80
  		https_port             = 443
  		origin_protocol_policy = "https-only"
  		origin_ssl_protocols   = ["TLSv1.2"]
  	}
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  aliases             = ["${local.sys_domain_name}"]
  price_class         = "PriceClass_All"
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.app1_bucket_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }
  
  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "${var.app1_name}/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.app1_bucket_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }
  
  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "${var.app2_name}/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.app2_bucket_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }
  
  # Cache behavior with precedence 2
  ordered_cache_behavior {
    path_pattern     = "/${var.api1_name}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.api_origin_id
    viewer_protocol_policy = "https-only"
    compress               = true
    
    # NOTE: To place CloudFront in front of API Gateway REST API, we cannot use managed cache policy and origin request policy.
    #       This is because API Gateway REST API is looking for a different host header than the incoming host header that is being forwarded. 
    #       The easiest way to resolve this is to use a new custom origin request policy that has query strings set to All, 
    #       but headers set to none (or only forwarded the appropriate headers that you do need).
	
    # APIs are usually not cacheable so it’s a sensible default to disable proxy caching on the CloudFront side. 
    # This can be done by specifying all cache TTLs as 0:
  	default_ttl = 0
	  min_ttl     = 0
	  max_ttl     = 0
    
	  # Usually, you want everything to be available (except some headers) for your API so it’s best to forward everything  (except some headers):
	  # The problematic header should be "Host". 
	  # When you set to pass all headers to the origin the 'Host' header is also passed and then API gateway receives an invalid host name in header and return 403.
    forwarded_values {
  		query_string = true
  		cookies {
  			forward = "all"
  		}
  	}
  
  }
  
  # Cache behavior with precedence 3
  ordered_cache_behavior {
    path_pattern     = "/${var.api2_name}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.api_origin_id
    viewer_protocol_policy = "https-only"
    compress               = true
    
    # NOTE: To place CloudFront in front of API Gateway REST API, we cannot use managed cache policy and origin request policy.
    #       This is because API Gateway REST API is looking for a different host header than the incoming host header that is being forwarded. 
    #       The easiest way to resolve this is to use a new custom origin request policy that has query strings set to All, 
    #       but headers set to none (or only forwarded the appropriate headers that you do need).
    
    # APIs are usually not cacheable so it’s a sensible default to disable proxy caching on the CloudFront side. 
    # This can be done by specifying all cache TTLs as 0:
  	default_ttl = 0
	  min_ttl     = 0
	  max_ttl     = 0
    
	  # Usually, you want everything to be available (except some headers) for your API so it’s best to forward everything  (except some headers):
	  # The problematic header should be "Host". 
	  # When you set to pass all headers to the origin the 'Host' header is also passed and then API gateway receives an invalid host name in header and return 403.
    forwarded_values {
  		query_string = true
  		cookies {
  			forward = "all"
  		}
  	}
    
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.sys_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
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

resource "aws_acm_certificate" "sys_cert" {
  provider = aws.global

  domain_name       = "${local.sys_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sys_cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.sys_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.sys_zone.zone_id
  records         = [each.value.record]
  ttl             = 300
}

resource "aws_acm_certificate_validation" "sys_cert_validation" {
  provider = aws.global
  certificate_arn         = aws_acm_certificate.sys_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.sys_cert_validation : record.fqdn]
}

#################
# DNS resources #
#################

resource "aws_route53_record" "sys_dns_record" {

  zone_id = data.aws_route53_zone.sys_zone.zone_id
  name    = "${local.sys_domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.sys_dist.domain_name
    zone_id                = aws_cloudfront_distribution.sys_dist.hosted_zone_id
    evaluate_target_health = false
  }

}
