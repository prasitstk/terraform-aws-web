###########
# Outputs #
###########

output "app_ctr_img_repo_url" {
  value = aws_ecr_repository.app_ctr_img_repo.repository_url
}

output "app_ctr_img_repo_name" {
  value = "${var.app_ctr_img_repo_name}"
}

output "app_ctr_img_tag" {
  value = "${var.app_ctr_img_tag}"
}

output "app_live_url" {
  value = "http://${aws_lb.app_alb.dns_name}"
}
