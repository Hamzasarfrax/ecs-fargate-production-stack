

# provider aws terraform 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # remote backed for state locking 
  backend "s3" {
    bucket         = "remote-backed-s3-bucket"
    key            = "stage/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "remote-backed-s3-bucket-locks"
    kms_key_id     = "alias/terraform-remote-state-key"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}
