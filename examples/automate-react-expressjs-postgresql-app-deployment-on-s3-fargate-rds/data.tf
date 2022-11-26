data "aws_caller_identity" "current" {}

data "aws_route53_zone" "app_zone" {
  name         = "${var.app_zone_name}."
  private_zone = false
}

data "aws_route53_zone" "api_zone" {
  name         = "${var.api_zone_name}."
  private_zone = false
}
