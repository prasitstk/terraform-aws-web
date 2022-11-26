output "app_live_url" {
  value = "https://${aws_route53_record.app_dns_record.fqdn}"
}

output "api_ctr_img_repo_url" {
  value = aws_ecr_repository.api_ctr_img_repo.repository_url
}

output "api_ctr_img_repo_name" {
  value = "${var.api_ctr_img_repo_name}"
}

output "api_ctr_img_tag" {
  value = "${var.api_ctr_img_tag}"
}

output "api_live_url" {
  value = "https://${aws_route53_record.api_dns_record.fqdn}"
}

output "data_dbi_db_name" {
  value = aws_db_instance.data_dbi.db_name
}

output "data_dbi_db_address" {
  value = aws_db_instance.data_dbi.address
}

output "data_dbi_db_port" {
  value = aws_db_instance.data_dbi.port
}

output "data_dbi_db_username" {
  value = aws_db_instance.data_dbi.username
}

output "data_dbi_db_password" {
  value     = "${var.data_master_db_password}"
  sensitive = true
}
