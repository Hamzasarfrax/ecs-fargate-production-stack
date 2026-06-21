terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  s3_use_path_style           = true

  endpoints {
    cloudfront = "http://localhost:4566"
    ec2        = "http://localhost:4566"
    s3         = "http://localhost:4566"
    sts        = "http://localhost:4566"
  }
}

locals {
  project_name = "portfolio-localstack"
  common_tags = {
    Environment = "localstack"
    ManagedBy   = "Terraform"
    Project     = local.project_name
  }
}

resource "aws_s3_bucket" "site" {
  bucket = "${local.project_name}-site"

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-site"
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content_type = "text/html"
  content      = "<h1>LocalStack portfolio platform</h1><p>S3 origin behind a CloudFront-style distribution.</p>"
}

resource "aws_instance" "demo" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = merge(local.common_tags, {
    Name = "local-ec2"
  })
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "LocalStack CloudFront-style distribution for portfolio testing"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "local-s3-origin"
  }

  default_cache_behavior {
    target_origin_id       = "local-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

output "localstack_s3_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "localstack_cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "localstack_ec2_instance_id" {
  value = aws_instance.demo.id
}
