######################
# REST API resources #
######################

resource "aws_api_gateway_rest_api" "app_rest_api" {
  name = "SimpleAPI"
  description = "A simple CORS compliant API"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "app_rest_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.app_rest_api.id
  parent_id   = aws_api_gateway_rest_api.app_rest_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_api_get_method" {
  rest_api_id      = aws_api_gateway_rest_api.app_rest_api.id
  resource_id      = aws_api_gateway_resource.app_rest_api_resource.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "hello_api_get_method_integration" {
  rest_api_id = aws_api_gateway_rest_api.app_rest_api.id
  resource_id = aws_api_gateway_resource.app_rest_api_resource.id
  http_method = aws_api_gateway_method.hello_api_get_method.http_method
  
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  
  request_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200
}
EOF
  }
}

resource "aws_api_gateway_method_response" "hello_api_get_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.app_rest_api.id
  resource_id = aws_api_gateway_resource.app_rest_api_resource.id
  http_method = aws_api_gateway_method.hello_api_get_method.http_method
  status_code = "200"
  
  response_parameters = { 
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "hello_api_get_method_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.app_rest_api.id
  resource_id = aws_api_gateway_resource.app_rest_api_resource.id
  http_method = aws_api_gateway_method.hello_api_get_method.http_method
  status_code = aws_api_gateway_method_response.hello_api_get_method_response_200.status_code
  
  selection_pattern = "200"
  
  response_parameters = { 
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  
  response_templates = {
    "application/json" = <<EOF
{"message": "Hello World!"}
EOF
  }

}

resource "aws_api_gateway_deployment" "app_rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.app_rest_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.app_rest_api_resource.id,
      aws_api_gateway_method.hello_api_get_method.id,
      aws_api_gateway_integration.hello_api_get_method_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "app_rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.app_rest_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.app_rest_api.id
  stage_name    = "v1"
}
