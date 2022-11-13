#################
# CDN resources #
#################

resource "aws_cloudfront_origin_access_identity" "app_bucket_dist_oai" {
  comment  = "access-identity-react-cors-spa-${aws_api_gateway_rest_api.app_rest_api.id}"
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

data "aws_cloudfront_origin_request_policy" "managed_cors_s3origin" {
  name = "Managed-CORS-S3Origin"
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
  price_class         = "PriceClass_All"
  
  logging_config {
    include_cookies = false
    bucket          = module.log_bucket.bucket.bucket_regional_domain_name
    prefix          = "cloudfront-access-logs"
  }

  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = local.app_bucket_origin_id
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = false
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3origin.id
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
}
