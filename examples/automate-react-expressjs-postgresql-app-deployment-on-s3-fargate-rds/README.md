# Automate React-ExpressJS-PostgreSQL App Deployment on S3-Fargate-RDS

&nbsp;

## Prerequisites

- An active AWS account with an IAM user that has required permissions to create/update/delete resources.
- Access key of the IAM User
- Terraform (version >= 0.13)
- Your S3 Static Website repository in a Git provider (BitBucket or GitHub)
- AWS CodeStar connection to your repository in [BitBucker](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-bitbucket.html) or [GitHub](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html) that is already available.
- Your registered domain name (It can be outside Amazon Route 53)
- Amazon Route 53 hosted zone of your domain name
- AWS CLI
- Docker
- Git

---

&nbsp;

## Tasks

Configure AWS CLI by:

```sh
aws configure
# AWS Access Key ID [None]: <your-aws-access-key>
# AWS Secret Access Key [None]: <your-aws-secret-key>
# Default region name [None]: <your-aws-access-region>
# Default output format [None]: json
```

Create `terraform.tfvars` to define variables for Terraform as follows:

```
aws_region                  = "<your-aws-region>"
aws_access_key              = "<your-aws-access-key>"
aws_secret_key              = "<your-aws-secret-key>"
sys_name                    = "tutorials"  # Can be changed
sys_vpc_cidr_block          = "10.0.0.0/16"  # Can be changed
app_zone_name               = "<your-app-domain.com>"
app_domain_name             = "<app-sub-domain>.<your-app-domain.com>"
app_codestar_connection_arn = "arn:aws:codestar-connections:<your-aws-region>:<AWS-Account-ID>:connection/<...>"
app_full_repository_id      = "<your-full-repository-id>"  # for example: "prasitstk/react-crud-web-api"
app_branch_name             = "<your-branch>"  # for example: "master"
api_zone_name               = "<your-api-domain.com>"
api_domain_name             = "<api-sub-domain>.<your-api-domain.com>"
api_src_repo_url            = "https://github.com/prasitstk/node-express-sequelize-postgresql.git"
api_ctr_img_tag             = "latest"
api_ctr_img_repo_name       = "node-express-sequelize-postgresql"  # Can be changed
api_svc_fixed_task_count    = 3    # Can be changed
api_cfg_port                = 8080
api_codestar_connection_arn = "arn:aws:codestar-connections:<your-aws-region>:<AWS-Account-ID>:connection/<...>"
api_full_repository_id      = "<your-full-repository-id>"  # for example: "prasitstk/node-express-sequelize-postgresql"
api_branch_name             = "<your-branch>"  # for example: "master"
data_db_name                = "tutorials_db"
data_master_db_password     = "<randomly-generated-manually>"
```

Initialize the project, plan, and apply the resource changes with the local state file by:

```sh
terraform init
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

---

&nbsp;

## Verification

Print the output to get the App URL by:

```sh
terraform output
# ...
# app_live_url = "https://<app_domain_name>"
```

Verify the result by browsing to that URL from `app_live_url` output to see whether you can play around the tutorial by adding, updating and removing tutorial data.

---

&nbsp;

## Clean up

To clean up the whole stack by deleting all of the resources, run the following command:

```sh
terraform destroy
```

---

&nbsp;

## References

Terraform
- [Terraform: Referencing resources created in for_each in another resource](https://stackoverflow.com/questions/63641187/terraform-referencing-resources-created-in-for-each-in-another-resource)
- [Terraform failing with Invalid for_each argument / The given "for_each" argument value is unsuitable](https://stackoverflow.com/questions/62264013/terraform-failing-with-invalid-for-each-argument-the-given-for-each-argument)
- [cidrsubnet Function](https://developer.hashicorp.com/terraform/language/functions/cidrsubnet)

Subnet
- [Automatically create a subnet for each AWS availability zone in Terraform](https://stackoverflow.com/questions/63991120/automatically-create-a-subnet-for-each-aws-availability-zone-in-terraform)

NAT Gateway
- [Do I need a separate NAT gateway for each private subnet?](https://stackoverflow.com/questions/54336982/do-i-need-a-separate-nat-gateway-for-each-private-subnet)
- [Setting up a NAT gateway on AWS using Terraform](https://dev.betterdoc.org/infrastructure/2020/02/04/setting-up-a-nat-gateway-on-aws-using-terraform.html)
- [Configure Multiple NAT gateways](https://stackoverflow.com/questions/71087224/configure-multiple-nat-gateways)
- [VPC with public and private subnets (NAT)](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html)

ECS
- [Tutorial: Amazon ECS Standard Deployment with CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html)
- [How to Deploy a Dockerised Application on AWS ECS With Terraform](https://medium.com/avmconsulting-blog/how-to-deploy-a-dockerised-node-js-application-on-aws-ecs-with-terraform-3e6bceb48785)

ECS Deployment with CodePipeline
- [Tutorial: Amazon ECS Standard Deployment with CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/ecs-cd-pipeline.html)
- [CI/CD Pipeline for Amazon ECS/FARGATE with Terraform](https://dev.to/erozedguy/ci-cd-pipeline-for-amazon-ecs-fargate-with-terraform-33na)
- [AWS Hands-On: Building CI/CD Pipeline For AWS ECS and Fargate Using Terrafo](https://hugh-choi.medium.com/building-ci-cd-pipeline-for-aws-ecs-and-fargate-using-terraform-be2795428459)
- [Discover Your IAM Role With: sts get-caller-identity](https://mikedalrymple.com/2019/09/04/discover-your-iam-role-with-sts-get-caller-identity/)
- [What is the proper way to log in to ECR?](https://serverfault.com/questions/1004915/what-is-the-proper-way-to-log-in-to-ecr)

---
