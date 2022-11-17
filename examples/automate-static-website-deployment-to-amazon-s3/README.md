# Automate static website deployment to Amazon S3

&nbsp;

## Prerequisites

- An active AWS account with an IAM user that has required permissions to create/update/delete resources.
- Access key of the IAM User
- Terraform (version >= 0.13)
- Your S3 Static Website repository in a Git provider (BitBucket or GitHub)
- AWS CodeStar connection to your repository in [BitBucker](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-bitbucket.html) or [GitHub](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html) that is already available.

> NOTE: During creating the AWS CodeStar connection, it should be better if you install the app to the connection that specific only to the repository to be deployed for the pipeline.

---

&nbsp;

## Tasks

Create `terraform.tfvars` to define variables for Terraform as follows:

```
aws_region                  = "<your-aws-region>"
aws_access_key              = "<your-aws-access-key>"
aws_secret_key              = "<your-aws-secret-key>"
website_bucket_name         = "<your-globally-unique-bucket-name>"
aws_codestar_connection_arn = "arn:aws:codestar-connections:ap-southeast-1:<AWS-Account-ID>:connection/<...>"
full_repository_id          = "<your-full-repository-id>"  # for example: "prasitstk/s3-static-site-demo"
branch_name                 = "<your-branch>"  # for example: "main"
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

Print the output to get the S3 static website URL by:

```sh
terraform output
# website_endpoint_url = "http://<your-globally-unique-bucket-name>.s3-website-<your-aws-region>.amazonaws.com"
```

Verify the result by browsing to that URL from `website_endpoint_url` output to see whether you see the content on `index.html` page.

Change your `index.html` page and push that changes to your Git repository on your Git provider.

Verify the result again by browsing to that URL to see whether the changes has been effective on the `index.html` page.

Now, try to browse to the URL of non-existing page to check whether it response to `error.html` page

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

- [Automate static website deployment to Amazon S3](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/automate-static-website-deployment-to-amazon-s3.html)
- [Learn / AWS - S3 Public Static Website](https://learn.openwaterfoundation.org/owf-learn-aws/website/s3/s3/)
- [Hosting a static website using Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [GitHub connections](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html)
- [Update a pending connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html)
- [Terraform = Resource: aws_codestarconnections_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection)
- [Tutorial: Create a pipeline that uses Amazon S3 as a deployment provider](https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-s3deploy.html)
- [Hosting a Secure Static Website on AWS S3 using Terraform (Step By Step Guide)](https://www.alexhyett.com/terraform-s3-static-website-hosting/)
- [Amazon S3 deploy action](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-S3Deploy.html)

---
