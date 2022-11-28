#########################
# API Gateway resources #
#########################

resource "aws_api_gateway_rest_api" "sys_rest_api" {
  name = "${var.sys_name}-rest-api"
}

module "api1_api_resource" {
  source   = "./modules/mock_api_resource"
  rest_api = aws_api_gateway_rest_api.sys_rest_api
  api_name = "${var.api1_name}"
}

module "api2_api_resource" {
  source   = "./modules/mock_api_resource"
  rest_api = aws_api_gateway_rest_api.sys_rest_api
  api_name = "${var.api2_name}"
}

resource "aws_api_gateway_deployment" "sys_rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sys_rest_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      module.api1_api_resource.api_resource.id,
      module.api1_api_resource.api_get_method.id,
      module.api1_api_resource.api_get_integration.id,
      module.api1_api_resource.api_post_method.id,
      module.api1_api_resource.api_post_integration.id,
      module.api2_api_resource.api_resource.id,
      module.api2_api_resource.api_get_method.id,
      module.api2_api_resource.api_get_integration.id,
      module.api2_api_resource.api_post_method.id,
      module.api2_api_resource.api_post_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "sys_rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.sys_rest_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sys_rest_api.id
  stage_name    = "${var.sys_api_stage_name}"
}
