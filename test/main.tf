terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
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

  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = "my-local-bucket"
}

resource "aws_instance" "demo" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "local-ec2"
  }
}
