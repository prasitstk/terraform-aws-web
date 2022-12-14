# Deploy a React-based single-page application to Amazon S3 and CloudFront

&nbsp;

## Prerequisites

- An active AWS account with an IAM user that has required permissions to create/update/delete resources.
- Access key of the IAM User
- Terraform (version >= 0.13)
- AWS CLI
- Node.js with NPM
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
aws_region     = "<your-aws-region>"
aws_access_key = "<your-aws-access-key>"
aws_secret_key = "<your-aws-secret-key>"
src_repo_url   = "https://github.com/prasitstk/react-cors-spa.git"  # Can be the other of your React SPA app repository
```

Initialize the project, plan, and apply the resource changes with the local state file by:

```sh
terraform init
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

> NOTE: If you update something on REST API resources later, please redeploy the API maually on API Gateway console.

---

&nbsp;

## Verification

Print the output to get the CloudFront URL by:

```sh
terraform output
# app_api_url = "https://<API-Gateway-API-ID>.execute-api.<your-aws-region>.amazonaws.com/v1"
# app_cf_url = "https://<your-unique-cloudfront-subdomain>.cloudfront.net"
```

Verify the result by browsing to that URL from `app_cf_url` output to see whether you see the content on `index.html` page.

Also verify that the React app requests the backend API endpoint `GET` to the URL from `app_api_url` output with `/hello` path at `<app_api_url>/hello` by going to `Network` tab on your Chrome `Developer Tools`.

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

- [Deploy a React-based single-page application to Amazon S3 and CloudFront](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-a-react-based-single-page-application-to-amazon-s3-and-cloudfront.html)
- [AWS CLI - Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [Terraform: Amazon API Gateway CORS](https://www.linkedin.com/pulse/terraform-amazon-api-gateway-cors-ahmad-ferdaus-abd-razak/?trk=pulse-article_more-articles_related-content-card)
- [Declare a simple REST API Gateway - Terraform](https://dev.to/mxglt/declare-a-simple-rest-api-gateway-terraform-5ci5)
- [AWS API Gateway with Terraform](https://medium.com/onfido-tech/aws-api-gateway-with-terraform-7a2bebe8b68f)
- [clouddrove/terraform-aws-api-gateway](https://github.com/clouddrove/terraform-aws-api-gateway)
- [cloudposse/terraform-aws-api-gateway](https://github.com/cloudposse/terraform-aws-api-gateway)

---
