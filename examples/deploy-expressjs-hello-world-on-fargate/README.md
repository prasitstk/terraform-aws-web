# Deploy Express Hello World application on AWS Fargate

&nbsp;

## Prerequisites

- An active AWS account with an IAM user that has required permissions to create/update/delete resources.
- Access key of the IAM User
- Terraform (version >= 0.13)
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
aws_region            = "<your-aws-region>"
aws_access_key        = "<your-aws-access-key>"
aws_secret_key        = "<your-aws-secret-key>"
src_repo_url          = "https://github.com/prasitstk/expressjs-hello-world.git"  # Can be the other of your express.js app repository
app_ctr_img_tag       = "latest"  # Can be changed
app_ctr_img_repo_name = "node-docker-ecs-app"  # Can be changed
app_vpc_cidr_block    = "10.0.0.0/16"  # Can be changed
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
# app_live_url = "http://<created-load-balancer-id>.<your-aws-region>.elb.amazonaws.com"
```

Verify the result by browsing to that URL from `app_live_url` output to see whether you see the hello world message.

---

&nbsp;

# Update source code and its image

Print the output to get the Image repository information by:

```sh
terraform output
# app_ctr_img_repo_url = "<your-aws-account-ID>.dkr.ecr.<your-aws-region>.amazonaws.com/<app_ctr_img_repo_name>"
# app_ctr_img_tag = "latest"
# ...
```

If you update something on your code and its Docker image of the application later, you can build and push the image into the ECR repository (with the same `app_ctr_img_tag` tag) by:

```sh
# First, Make sure that awscli is version 2.
aws configure
aws ecr get-login-password --region <your-aws-region> | docker login --username AWS --password-stdin <your-aws-account-ID>.dkr.ecr.<your-aws-region>.amazonaws.com

docker build -t <app_ctr_img_repo_name> .
docker tag <app_ctr_img_repo_name>:latest <app_ctr_img_repo_url>:<app_ctr_img_tag>
docker push <app_ctr_img_repo_url>:<app_ctr_img_tag>
```

Then, to redeploy the update on ECS service, re-run the following `terraform` commands to update the ECS task definition by the updated image digest:

```sh
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

Finally, the new version of the ECS task definition will be created and the ECS service which refers to that task definition will provision the new tasks based on that updated version of that task definition.

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

- [How to Deploy a Dockerised Application on AWS ECS With Terraform](https://medium.com/avmconsulting-blog/how-to-deploy-a-dockerised-node-js-application-on-aws-ecs-with-terraform-3e6bceb48785)
- [Using Terraform to provision Amazon’s ECR, and ECS to manage containers (docker)](https://www.oneworldcoders.com/blog/using-terraform-to-provision-amazons-ecr-and-ecs-to-manage-containers-docker)
- [Resource: aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
- [force_new_deployment does not redeploy the ecs service #13528](https://github.com/hashicorp/terraform-provider-aws/issues/13528)
- [CI/CD — Force Redeploy AWS ECS Fargate For Same Docker Image NameTag With Terraform](https://amithkumarg.medium.com/terraform-force-redeploy-aws-ecs-fargate-for-same-docker-image-tag-2089b81f02c2)
- [Pulling an image](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-pull-ecr-image.html)
- [Automation Deletion Untagged Container Image in Amazon ECR Using ECR Lifecycle Policy](https://aws.plainenglish.io/automation-deletion-untagged-container-image-in-amazon-ecr-using-ecr-lifecycle-policy-995eae2f5b8d)

---
