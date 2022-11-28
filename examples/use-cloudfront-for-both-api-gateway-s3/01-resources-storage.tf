#####################
# Storage resources #
#####################

module "app1_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "${var.app1_name}.${var.sys_zone_name}"
  force_destroy = true
  acl           = "private"
}

resource "aws_s3_object" "app1_index_html" {
  key     = "${var.app1_name}/index.html"
  bucket  = module.app1_bucket.bucket.id
  content = templatefile("${path.module}/files/aws_s3_object/index.html.tftpl", {
    app_name = "${var.app1_name}"
  })
  content_type = "text/html"
}

module "app2_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "${var.app2_name}.${var.sys_zone_name}"
  force_destroy = true
  acl           = "private"
}

resource "aws_s3_object" "app2_index_html" {
  key     = "${var.app2_name}/index.html"
  bucket  = module.app2_bucket.bucket.id
  content = templatefile("${path.module}/files/aws_s3_object/index.html.tftpl", {
    app_name = "${var.app2_name}"
  })
  content_type = "text/html"
}
