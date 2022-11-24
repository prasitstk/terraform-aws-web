#################
# EC2 Resources #
#################

resource "aws_lb" "app_alb" {
  name               = "app-alb" # Naming our load balancer
  internal           = false
  load_balancer_type = "application"
  
  subnets         = [for s in aws_subnet.app_public_subnets: "${s.id}"]
  security_groups = ["${aws_security_group.app_alb_sg.id}"]
  
  access_logs {
    bucket  = ""
    enabled = false
    prefix  = ""
  }
}

resource "aws_lb_target_group" "app_tgtgrp" {
  name        = "app-tgtgrp"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.app_vpc.id}"
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "app_alb_listener_80" {
  load_balancer_arn = aws_lb.app_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.app_tgtgrp.arn}"
  }
}
