#####################
# Storage resources #
#####################

# Website bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket        = "${var.website_bucket_name}"
  force_destroy = true
}

# Website bucket :: Bucket policy
data "aws_iam_policy_document" "website_bucket_policy" {
  statement {
    sid = "PublicReadGetObject"
  
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.website_bucket_policy.json
}

# Website bucket :: Static site configuration
resource "aws_s3_bucket_website_configuration" "website_bucket_policy_website_cfg" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
