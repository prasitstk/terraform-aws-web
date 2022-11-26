#############################
# SSL certificate resources #
#############################

resource "aws_acm_certificate" "api_cert" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${var.sys_name}-api-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api_cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.api_zone.zone_id
  records         = [each.value.record]
  ttl             = 300
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

#################
# DNS resources #
#################

resource "aws_route53_record" "api_dns_record" {

  zone_id = data.aws_route53_zone.api_zone.zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.api_alb.dns_name
    zone_id                = aws_lb.api_alb.zone_id
    evaluate_target_health = true
  }

}

#################
# EC2 resources #
#################

resource "aws_lb" "api_alb" {
  name               = "${var.sys_name}-api-alb" # Naming our load balancer
  internal           = false
  load_balancer_type = "application"
  
  subnets         = [for s in aws_subnet.sys_public_subnets: "${s.id}"]
  security_groups = ["${aws_security_group.api_alb_sg.id}"]
  
  access_logs {
    bucket  = ""
    enabled = false
    prefix  = ""
  }
}

resource "aws_lb_target_group" "api_tgtgrp" {
  name        = "${var.sys_name}-api-tgtgrp"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.sys_vpc.id}"
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "api_alb_listener_80" {
  load_balancer_arn = aws_lb.api_alb.arn

  port     = 80
  protocol = "HTTP"
  
  default_action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "api_alb_listener_443" {
  load_balancer_arn = aws_lb.api_alb.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tgtgrp.arn
  }
}

resource "aws_lb_listener_rule" "api_alb_listener_443_rule_robot_txt" {
  listener_arn = aws_lb_listener.api_alb_listener_443.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/robots.txt"]
    }
  }

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "User-agent: *\nDisallow: /\n"
      status_code  = "200"
    }
  }
}
