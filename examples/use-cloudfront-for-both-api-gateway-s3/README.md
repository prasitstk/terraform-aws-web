# Use CloudFront for both API Gateway and S3

&nbsp;

## Prerequisites

- An active AWS account with an IAM user that has required permissions to create/update/delete resources.
- Access key of the IAM User
- Terraform (version >= 0.13)
- Your registered domain name (It can be outside Amazon Route 53)
- Amazon Route 53 hosted zone of your domain name

---

&nbsp;

## Tasks

Create `terraform.tfvars` to define variables for Terraform as follows:

```
aws_region         = "<your-aws-region>"
aws_access_key     = "<your-aws-access-key>"
aws_secret_key     = "<your-aws-secret-key>"
sys_name           = "your-sys"  # Can be changed
sys_zone_name      = "your-domain.com"  # Can be changed
sys_api_stage_name = "test"  # Can be changed
app1_name          = "app1"  # Can be changed
app2_name          = "app2"  # Can be changed
api1_name          = "api1"  # Can be changed
api2_name          = "api2"  # Can be changed
```

Initialize the project, plan, and apply the resource changes with the local state file by:

```sh
terraform init
terraform plan -out /tmp/tfplan
terraform apply /tmp/tfplan
```

> NOTE: For some reason, after you initiate or update the CloudFront configuration on Terraform files, you need to redeploy your REST API in API Gateway manually to make REST API effective on CloudFront.

---

&nbsp;

## Verification

### App-1

Browse to `https://your-sys.your-domain.com/<your-app1_name>/index.html` web page and it should show the message "Hello from <your-app1_name>!" on your brownser.

### App-2

Browse to `https://your-sys.your-domain.com/<your-app2_name>/index.html` web page and it should show the message "Hello from <your-app2_name>!" on your brownser.

### API-1

Request to `GET https://your-sys.your-domain.com/<your-api1_name>?scope=internal` API and it should response 200 HTTP status with the following JSON body:
```json
{
	"statusCode": 200,
	"message": "<your-api1_name> API OK message from GET method"
}
```

Request to `GET https://your-sys.your-domain.com/<your-api1_name>?scope=public` API with wrong inputs and it should response 500 HTTP status with the following JSON body:
```json
{
	"statusCode": 500,
	"message": "<your-api1_name> API error message from GET method"
}
```

Request to `POST https://your-sys.your-domain.com/<your-api1_name>` API with the header `Content-Type: application/json` and the following JSON input body:
```json
{"scope":"internal"}
```

- It should response the 200 HTTP status with the JSON body as follows:
```json
{
	"statusCode": 200,
	"message": "<your-api1_name> API OK message from POST method"
}
```

Request to `POST https://your-sys.your-domain.com/<your-api1_name>` API with the header `Content-Type: application/json` and the following wrong JSON input body:
```json
{"scope":"public"}
```

- It should response the 500 HTTP status with the JSON body as follows:
```json
{
	"statusCode": 500,
	"message": "<your-api1_name> API error message from POST method"
}
```

### API-2

Request to `GET https://your-sys.your-domain.com/<your-api2_name>?scope=internal` API and it should response 200 HTTP status with the following JSON body:
```json
{
	"statusCode": 200,
	"message": "<your-api2_name> API OK message from GET method"
}
```

Request to `GET https://your-sys.your-domain.com/<your-api2_name>?scope=public` API with wrong inputs and it should response 500 HTTP status with the following JSON body:
```json
{
	"statusCode": 500,
	"message": "<your-api2_name> API error message from GET method"
}
```

Request to `POST https://your-sys.your-domain.com/<your-api2_name>` API with the header `Content-Type: application/json` and the following JSON input body:
```json
{"scope":"internal"}
```

- It should response the 200 HTTP status with the JSON body as follows:
```json
{
	"statusCode": 200,
	"message": "<your-api2_name> API OK message from POST method"
}
```

Request to `POST https://your-sys.your-domain.com/<your-api2_name>` API with the header `Content-Type: application/json` and the following wrong JSON input body:
```json
{"scope":"public"}
```

- It should response the 500 HTTP status with the JSON body as follows:
```json
{
	"statusCode": 500,
	"message": "<your-api2_name> API error message from POST method"
}
```

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

- [Use CloudFront for API Gateway & S3](https://medium.com/vectoscalar/use-cloudfront-for-api-gateway-s3-both-cc0e30e0962a)
- [SERVING MULTIPLE S3 BUCKETS VIA SINGLE AWS CLOUDFRONT DISTRIBUTION](https://vimalpaliwal.com/blog/2018/10/10f435c29f/serving-multiple-s3-buckets-via-single-aws-cloudfront-distribution.html)
- [How to route to multiple origins with CloudFront](https://advancedweb.hu/how-to-route-to-multiple-origins-with-cloudfront/)
- [How do I set up API Gateway with my own CloudFront distribution?](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-cloudfront-distribution/)
- [How to manually invalidate AWS CloudFront](https://christinavhastenrath.medium.com/how-to-manually-invalidate-aws-cloudfront-b36a2ab4e1be)

Problem with forwarded header from CloudFront
- [[Cloudfront]The Request are failing with error code 403 after enabling ALL_viewer origin request policy](https://repost.aws/questions/QUoVT6GlyGTa-Y-SM4ZkClpA/cloudfront-the-request-are-failing-with-error-code-403-after-enabling-all-viewer-origin-request-policy)
- [CloudFront + API Gateway: Error 403 - Bad request](https://www.reddit.com/r/aws/comments/fyfwt7/cloudfront_api_gateway_error_403_bad_request/)
- [CloudFront gives 403 when origin request policy (Include all headers & querystring) is added?](https://stackoverflow.com/questions/71367982/cloudfront-gives-403-when-origin-request-policy-include-all-headers-querystri)

---
