# LocalStack Terraform Test

This folder is for local AWS practice without creating real AWS resources or cost.

It tests a small production-like flow:

- S3 bucket as a static origin.
- CloudFront-style distribution in Terraform.
- EC2 mock resource.
- LocalStack AWS provider endpoints.

## Start LocalStack

```powershell
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack
```

Keep this terminal running.

## Run Terraform

Open another terminal:

```powershell
cd test
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## Notes

- The provider uses fake credentials: `access_key = "test"` and `secret_key = "test"`.
- All configured endpoints point to `http://localhost:4566`.
- CloudFront support depends on the LocalStack version/edition installed on your machine. If CloudFront apply fails locally, keep the Terraform code as production-style learning and test S3/EC2 locally.
- This folder should stay separate from `env/dev`, `env/stag`, and `env/prod` so real AWS environments remain clean.

## Useful Checks

```powershell
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3 ls s3://portfolio-localstack-site
```
