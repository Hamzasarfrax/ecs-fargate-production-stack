variable "name" {
  description = "Name of the Load Balancer"
  type        = string
}

variable "internal" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "idle_timeout" {
  type    = number
  default = 60
}

variable "enable_deletion_protection" {
  description = "Production mein accidental deletion se bachane ke liye true hona chahiye"
  type        = bool
  default     = false
}

variable "client_keep_alive" {
  type    = number
  default = 3600
}

variable "drop_invalid_header_fields" {
  description = "Security best practice to drop invalid headers"
  type        = bool
  default     = true
}

variable "enable_http2" {
  type    = bool
  default = true
}

variable "enable_waf_fail_open" {
  type    = bool
  default = false
}

variable "xff_header_processing_mode" {
  type    = string
  default = "append"
}

variable "enable_cross_zone_load_balancing" {
  type    = bool
  default = true
}

variable "ip_address_type" {
  type    = string
  default = "ipv4"
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  type    = string
  default = "alb-logs"
}

variable "access_logs_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "tg_name" {
  type = string
}

variable "tg_port" {
  type    = number
  default = 80
}

variable "tg_protocol" {
  type    = string
  default = "HTTP"
}

variable "target_type" {
  type    = string
  default = "ip"
}

variable "vpc_id" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_protocol" {
  type    = string
  default = "HTTP"
}

variable "enable_stickiness" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "WAF protection for production workloads"
  type        = bool
  default     = true
}
