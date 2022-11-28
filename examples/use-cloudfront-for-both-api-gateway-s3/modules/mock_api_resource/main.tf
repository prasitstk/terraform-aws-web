resource "aws_api_gateway_resource" "this" {
  rest_api_id = var.rest_api.id
  parent_id   = var.rest_api.root_resource_id
  path_part   = "${var.api_name}"
}

########################
# GET method resources #
########################

resource "aws_api_gateway_method" "this_get" {
  rest_api_id   = var.rest_api.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this_get_integration" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_get.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = <<EOF
{
#if( $input.params('scope') == "internal" )
  "statusCode": 200
#else
  "statusCode": 500
#end
}
EOF
  }
}

resource "aws_api_gateway_method_response" "this_get_resp_200" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "this_get_integration_get_resp_200" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_get.http_method
  status_code = aws_api_gateway_method_response.this_get_resp_200.status_code

  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "message": "${var.api_name} API OK message from GET method"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "this_get_resp_500" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_get.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "this_get_integration_get_resp_500" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_get.http_method
  status_code = aws_api_gateway_method_response.this_get_resp_500.status_code
  
  selection_pattern  = "5\\d{2}"
  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 500,
  "message": "${var.api_name} API error message from GET method"
}
EOF
  }
}

#########################
# POST method resources #
#########################

resource "aws_api_gateway_method" "this_post" {
  rest_api_id   = var.rest_api.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this_post_integration" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_post.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = <<EOF
{
#if( $input.path('$.scope') == "internal" )
  "statusCode": 200
#else
  "statusCode": 500
#end
}
EOF
  }
}

resource "aws_api_gateway_method_response" "this_post_resp_200" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "this_post_integration_post_resp_200" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_post.http_method
  status_code = aws_api_gateway_method_response.this_post_resp_200.status_code

  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "message": "${var.api_name} API OK message from POST method"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "this_post_resp_500" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_post.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "this_post_integration_post_resp_500" {
  rest_api_id = var.rest_api.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this_post.http_method
  status_code = aws_api_gateway_method_response.this_post_resp_500.status_code
  
  selection_pattern  = "5\\d{2}"
  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 500,
  "message": "${var.api_name} API error message from POST method"
}
EOF
  }
}
