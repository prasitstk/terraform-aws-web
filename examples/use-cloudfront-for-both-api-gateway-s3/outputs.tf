output "app1_live_url" {
  value = "https://${var.sys_name}.${var.sys_zone_name}/${var.app1_name}/index.html"
}

output "app2_live_url" {
  value = "https://${var.sys_name}.${var.sys_zone_name}/${var.app2_name}/index.html"
}

output "api1_live_url" {
  value = "https://${var.sys_name}.${var.sys_zone_name}/${var.api1_name}"
}

output "api2_live_url" {
  value = "https://${var.sys_name}.${var.sys_zone_name}/${var.api2_name}"
}
