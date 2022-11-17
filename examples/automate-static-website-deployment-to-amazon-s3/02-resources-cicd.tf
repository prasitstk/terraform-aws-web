###################
# CI/CD resources #
###################

# CodePipeline artifact store bucket of the pipeline
module "codepipeline_website_bucket" {
  source        = "../../modules/s3-bucket"
  bucket        = "codepipeline-website-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  acl           = "private"
}

# CodePipeline IAM base policy of the pipeline
resource "aws_iam_policy" "codepipeline_website_base_policy" {
  name        = "CodePipelineBasePolicy-website-${var.aws_region}"
  description = "Policy used in trust relationship with CodePipeline"
  path        = "/service-role/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Effect   = "Allow"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ]
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Effect = "Allow"
        Action = [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ]
        Resource = "*"
      }
    ]
  })

}

# CodePipeline IAM service role of the pipeline
resource "aws_iam_role" "codepipeline_website_service_role" {
  name = "codepipeline-website-service-role-${var.aws_region}"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.codepipeline_website_base_policy.arn
  ]
}

# CodePipeline pipeline
resource "aws_codepipeline" "website_pipeline" {
  name     = "${var.website_bucket_name}"
  role_arn = aws_iam_role.codepipeline_website_service_role.arn

  artifact_store {
    location = module.codepipeline_website_bucket.bucket.bucket
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
        ConnectionArn    = var.aws_codestar_connection_arn
        FullRepositoryId = var.full_repository_id
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      run_order       = 1
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["SourceArtifact"]
      version         = "1"
      namespace       = "DeployVariables"

      configuration = {
        BucketName = "${var.website_bucket_name}"
        Extract    = true
      }
    }

  }

}
