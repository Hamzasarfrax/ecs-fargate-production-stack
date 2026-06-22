variable "name" {
  description = "Name prefix for the CloudFront distribution."
  type        = string
}

variable "enabled" {
  description = "Enable or disable the CloudFront distribution."
  type        = bool
  default     = true
}

variable "origin_domain_name" {
  description = "DNS name of the origin, usually the ALB DNS name."
  type        = string
}

variable "origin_id" {
  description = "Stable origin identifier."
  type        = string
  default     = "alb-origin"
}

variable "origin_protocol_policy" {
  description = "CloudFront to origin protocol policy."
  type        = string
  default     = "http-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.origin_protocol_policy)
    error_message = "origin_protocol_policy must be http-only, https-only, or match-viewer."
  }
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy."
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "aliases" {
  description = "Optional custom domain aliases for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom CloudFront aliases. Must be in us-east-1."
  type        = string
  default     = null
}

variable "default_ttl" {
  description = "Default cache TTL in seconds. Keep 0 for dynamic ALB/ECS workloads."
  type        = number
  default     = 0
}

variable "min_ttl" {
  description = "Minimum cache TTL in seconds."
  type        = number
  default     = 0
}

variable "max_ttl" {
  description = "Maximum cache TTL in seconds."
  type        = number
  default     = 0
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "web_acl_id" {
  description = "Optional AWS WAF web ACL ARN for CloudFront scope."
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "Optional S3 bucket domain name for CloudFront logs, e.g. bucket.s3.amazonaws.com."
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "CloudFront access log prefix."
  type        = string
  default     = "cloudfront/"
}

variable "tags" {
  description = "Tags to apply to CloudFront resources."
  type        = map(string)
  default     = {}
}
