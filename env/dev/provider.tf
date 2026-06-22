

# provider aws terraform 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # remote backed for state locking 
  # backend "s3" {
  #   bucket         = "remote-backed-s3-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "remote-backed-s3-bucket-locks"
  #   kms_key_id     = "alias/terraform-remote-state-key"
  # }



  backend "s3" {
    bucket = "remote-backed-s3-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    endpoints = {
      s3 = "http://localhost:4566"
    }
    force_path_style = true
  }

}

provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  s3_use_path_style           = true

  endpoints {
    cloudfront  = "http://localhost:4566"
    s3          = "http://localhost:4566"
    ec2         = "http://localhost:4566"
    sts         = "http://localhost:4566"
    iam         = "http://localhost:4566"
    dynamodb    = "http://localhost:4566"
    kms         = "http://localhost:4566"
    cloudwatch  = "http://localhost:4566"
    logs        = "http://localhost:4566"
    ecr         = "http://localhost:4566"
    ecs         = "http://localhost:4566"
    elbv2       = "http://localhost:4566"
    ssm         = "http://localhost:4566"
    sns         = "http://localhost:4566"
    sqs         = "http://localhost:4566"
    rds         = "http://localhost:4566"
    autoscaling = "http://localhost:4566"
    events      = "http://localhost:4566"

  }
}
