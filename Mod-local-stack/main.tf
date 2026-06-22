terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  s3_use_path_style           = true
  endpoints {
    s3 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "demo" {
  bucket = "my-localstack-demo-bucket"
}

resource "aws_s3_object" "file" {
  bucket       = aws_s3_bucket.demo.id
  key          = "index.html"
  content_type = "text/html"
  content      = "<h1>LocalStack S3 is working 🚀</h1>"
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
