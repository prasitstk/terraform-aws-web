###################
# CI/CD resources #
###################

#---------------------#
# CodeBuild resources #
#---------------------#

resource "aws_iam_policy" "api_bldproj_base_policy" {
  name        = "CodeBuildBasePolicy-${var.sys_name}-api-bldproj-${var.aws_region}"
  description = "Policy used in trust relationship with CodeBuild"
  path        = "/service-role/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.sys_name}-api-bldproj",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.sys_name}-api-bldproj:*"
        ]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::codepipeline-${var.sys_name}-${var.aws_region}-*"
        ]
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = [
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:report-group/${var.sys_name}-api-bldproj-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_api_service_role" {
  name = "codebuild-${var.sys_name}-api-service-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.api_bldproj_base_policy.arn,
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]

}

resource "aws_codebuild_project" "api_bldproj" {
  name         = "${var.sys_name}-api-bldproj"
  service_role = aws_iam_role.codebuild_api_service_role.arn

  source {
    buildspec = templatefile("${path.module}/files/aws_codebuild_project/api_bldproj/buildspec.yml.tftpl", {
      repository_name = aws_ecr_repository.api_ctr_img_repo.name
      container_name  = "${var.sys_name}-api-task"
    })
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true  # enable running the Docker daemon inside a Docker container
  }
}

#------------------------#
# CodePipeline resources #
#------------------------#

resource "aws_codepipeline" "api_pipeline" {
  name     = "${var.sys_name}-api-pipeline"
  role_arn = aws_iam_role.codepipeline_sys_service_role.arn

  artifact_store {
    location = module.codepipeline_sys_bucket.bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = var.api_codestar_connection_arn
        FullRepositoryId = var.api_full_repository_id
        BranchName       = var.api_branch_name
      }
    }
  }
  
  stage {
    name = "Build"

    action {
      run_order        = 1
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      version          = "1"
      namespace        = "BuildVariables"
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.api_bldproj.name
      }
    }

  }
  
  stage {
    name = "Deploy"
    
    action {
      run_order       = 2
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.api_ctr_cluster.name
        ServiceName = aws_ecs_service.api_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

}
