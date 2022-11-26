#################
# ECR Resources #
#################

resource "aws_ecr_repository" "api_ctr_img_repo" {
  name                 = "${var.api_ctr_img_repo_name}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api_ctr_img_repo_lifecycle" {
  repository = aws_ecr_repository.api_ctr_img_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

################
# Provisioning #
################

resource "null_resource" "git_clone_from_src_repo" {
  triggers = {
    required_resource_id = aws_ecr_repository.api_ctr_img_repo.repository_url
  }
  
  provisioner "local-exec" {
    command = <<EOF
docker rmi ${aws_ecr_repository.api_ctr_img_repo.repository_url}:${var.api_ctr_img_tag} && \
  docker rmi ${var.api_ctr_img_repo_name}:latest && \
  rm -rf /tmp/${replace(reverse(split("/", var.api_src_repo_url))[0], ".git", "")}
  cd /tmp && \ 
  git clone ${var.api_src_repo_url}
EOF
  }
}

resource "null_resource" "docker_build_push_to_ecr_repo" {
  triggers = {
    required_resource_id = null_resource.git_clone_from_src_repo.id
  }
  
  provisioner "local-exec" {
    command = <<EOF
cd /tmp/${replace(reverse(split("/", var.api_src_repo_url))[0], ".git", "")} && \
  export AWS_ACCESS_KEY_ID="${var.aws_access_key}" && \
  export AWS_SECRET_ACCESS_KEY="${var.aws_secret_key}" && \
  export AWS_DEFAULT_REGION="${var.aws_region}" && \
  aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com && \
  docker build -t ${var.api_ctr_img_repo_name} . && \
  docker tag ${var.api_ctr_img_repo_name}:latest ${aws_ecr_repository.api_ctr_img_repo.repository_url}:${var.api_ctr_img_tag} && \
  docker push ${aws_ecr_repository.api_ctr_img_repo.repository_url}:${var.api_ctr_img_tag}
EOF
  }
}

resource "null_resource" "cleanup_after_init_api_ctr_img" {
  triggers = {
    required_resource_id = null_resource.docker_build_push_to_ecr_repo.id
  }
  
  provisioner "local-exec" {
    command = <<EOF
docker rmi ${aws_ecr_repository.api_ctr_img_repo.repository_url}:${var.api_ctr_img_tag} && \
  docker rmi ${var.api_ctr_img_repo_name}:latest && \
  rm -rf /tmp/${replace(reverse(split("/", var.api_src_repo_url))[0], ".git", "")}
EOF
  }  
}
