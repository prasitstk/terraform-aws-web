################
# Provisioning #
################

resource "null_resource" "git_clone_from_src_repo" {
  triggers = {
    # NOTE: If you would like to re-run no matter what, please change it to `required_resource_id = timestamp()` instead.
    required_resource_id = module.app_bucket.bucket.id
  }
  
  provisioner "local-exec" {
    command = <<EOF
rm -rf /tmp/${replace(reverse(split("/", var.src_repo_url))[0], ".git", "")} && \ 
  cd /tmp && \ 
  git clone ${var.src_repo_url}
EOF
  }
}

resource "null_resource" "build_and_deploy_app_to_app_bucket" {
  triggers = {
    required_resource_id = null_resource.git_clone_from_src_repo.id
  }
  
  provisioner "local-exec" {
    command = <<EOF
cd /tmp/${replace(reverse(split("/", var.src_repo_url))[0], ".git", "")} && \
  npm install && \
  echo "REACT_APP_API_ENDPOINT=https://${aws_api_gateway_rest_api.app_rest_api.id}.execute-api.${var.aws_region}.amazonaws.com/v1/hello" > .env && \
  npm run build && \
  export AWS_ACCESS_KEY_ID=${var.aws_access_key} && \
  export AWS_SECRET_ACCESS_KEY=${var.aws_secret_key} && \
  export AWS_DEFAULT_REGION=${var.aws_region} && \
  aws s3 rm s3://${module.app_bucket.bucket.id}/ --recursive && \
  aws s3 sync build/ s3://${module.app_bucket.bucket.id}/
EOF
  }
}
