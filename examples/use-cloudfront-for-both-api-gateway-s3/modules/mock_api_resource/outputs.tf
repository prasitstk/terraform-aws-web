###########
# Outputs #
###########

output "api_resource" {
  value = aws_api_gateway_resource.this
}

output "api_get_method" {
  value = aws_api_gateway_method.this_get
}

output "api_get_integration" {
  value = aws_api_gateway_integration.this_get_integration
}

output "api_post_method" {
  value = aws_api_gateway_method.this_post
}

output "api_post_integration" {
  value = aws_api_gateway_integration.this_post_integration
}
