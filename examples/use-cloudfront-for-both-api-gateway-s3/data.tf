###############
# Datasources #
###############

data "aws_route53_zone" "sys_zone" {
  name         = "${var.sys_zone_name}."
  private_zone = false
}
