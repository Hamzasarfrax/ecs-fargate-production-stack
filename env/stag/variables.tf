variable "repository_name" {
  type    = string
  default = "repository_image"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener on the ALB"
  type        = string
  default     = null
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting"

  type    = string
  default = "IMMUTABLE"

  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE"],
      var.image_tag_mutability
    )

    error_message = "Valid values are MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "portfolio-aws-platform-stage"
}

variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for CloudWatch/SNS alerts."
  type        = string
  default     = "alerts@example.com"
}

variable "alb_access_logs_bucket" {
  description = "Existing S3 bucket for ALB access logs. Keep null in local/dev unless you have created one."
  type        = string
  default     = null
}

variable "enable_cloudfront" {
  description = "Enable CloudFront in front of the ALB."
  type        = bool
  default     = true
}

variable "cloudfront_aliases" {
  description = "Optional custom domains for CloudFront."
  type        = list(string)
  default     = []
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront aliases. Must be issued in us-east-1."
  type        = string
  default     = null
}

variable "cloudfront_logging_bucket" {
  description = "Optional S3 bucket domain name for CloudFront logs, e.g. logs-bucket.s3.amazonaws.com."
  type        = string
  default     = null
}

# for vpc

variable "nat_gateway_strategy" {
  type    = string
  default = "none"

  validation {
    condition = contains(
      ["single", "one_per_az", "none"],
      var.nat_gateway_strategy
    )

    error_message = "nat_gateway_strategy must be single, one_per_az, or none."
  }
}
