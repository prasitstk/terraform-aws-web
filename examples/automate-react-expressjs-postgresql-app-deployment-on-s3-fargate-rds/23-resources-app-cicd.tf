###################
# CI/CD resources #
###################

#----------------#
# SSM Parameters #
#----------------#

resource "aws_ssm_parameter" "codepipeline_app_website_s3_bucket" {
  name  = "/codepipeline/${var.sys_name}-app/WEBSITE_S3_BUCKET"
  type  = "String"
  value = module.app_bucket.bucket.bucket
}

resource "aws_ssm_parameter" "codepipeline_app_cloudfront_dist_id" {
  name  = "/codepipeline/${var.sys_name}-app/CLOUDFRONT_DIST_ID"
  type  = "String"
  value = aws_cloudfront_distribution.app_bucket_dist.id
}

resource "aws_ssm_parameter" "codepipeline_app_dotenv" {
  name = "/codepipeline/${var.sys_name}-app/DOTENV"
  type = "String"
  value = templatefile("${path.module}/files/aws_ssm_parameter/codepipeline_app/dotenv.tftpl", {
    api_domain_name = var.api_domain_name
  })
}

#---------------------#
# CodeBuild resources #
#---------------------#

resource "aws_iam_policy" "app_bldproj_base_policy" {
  name        = "CodeBuildBasePolicy-${var.sys_name}-app-bldproj-${var.aws_region}"
  description = "Policy used in trust relationship with CodeBuild"
  path        = "/service-role/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.sys_name}-app-bldproj",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.sys_name}-app-bldproj:*"
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
          "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:report-group/${var.sys_name}-app-bldproj-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_app_service_role" {
  name = "codebuild-${var.sys_name}-app-service-role"
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
    aws_iam_policy.app_bldproj_base_policy.arn,
    "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  ]

  inline_policy {
    name = "s3-delete-object"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "VisualEditor0"
          Effect   = "Allow"
          Action   = "s3:DeleteObject"
          Resource = "arn:aws:s3:::${module.app_bucket.bucket.bucket}/*"
        }
      ]
    })
  }

  inline_policy {
    name = "s3-sync"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::${module.app_bucket.bucket.bucket}/*",
            "arn:aws:s3:::${module.app_bucket.bucket.bucket}"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "ssm-get-parameters"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          Resource = [
            "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/codepipeline/${var.sys_name}-app/*"
          ]
        }
      ]
    })
  }

}

resource "aws_codebuild_project" "app_bldproj" {
  name         = "${var.sys_name}-app-bldproj"
  service_role = aws_iam_role.codebuild_app_service_role.arn

  source {
    buildspec = file("${path.module}/files/aws_codebuild_project/app_bldproj/buildspec.yml")
    type      = "CODEPIPELINE"
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
  }
}

#------------------------#
# CodePipeline resources #
#------------------------#

resource "aws_codepipeline" "app_pipeline" {
  name     = "${var.sys_name}-app-pipeline"
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
        ConnectionArn    = var.app_codestar_connection_arn
        FullRepositoryId = var.app_full_repository_id
        BranchName       = var.app_branch_name
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
        ProjectName = aws_codebuild_project.app_bldproj.name
        EnvironmentVariables = jsonencode([
          {
            name  = "DOTENV"
            value = aws_ssm_parameter.codepipeline_app_dotenv.name
            type  = "PARAMETER_STORE"
          },
          {
            name  = "WEBSITE_S3_BUCKET"
            value = aws_ssm_parameter.codepipeline_app_website_s3_bucket.name
            type  = "PARAMETER_STORE"
          },
          {
            name  = "CLOUDFRONT_DIST_ID"
            value = aws_ssm_parameter.codepipeline_app_cloudfront_dist_id.name
            type  = "PARAMETER_STORE"
          }
        ])
      }
    }

  }

}
