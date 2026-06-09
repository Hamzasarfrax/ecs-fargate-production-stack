variable "name" {
  type = string
}

variable "internal" {
  type    = bool
  default = false
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "idle_timeout" {
  type    = number
  default = 60
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "client_keep_alive" {
  type    = number
  default = 3600
}

variable "drop_invalid_header_fields" {
  type    = bool
  default = false
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
  validation {
    condition = contains(
      ["ipv4", "dualstack"],
      var.ip_address_type
    )
    error_message = "ip_address_type must be ipv4 or dualstack."
  }
}

# --------------------
# Access Logs
# --------------------

variable "access_logs_bucket" {
  type = string
}

variable "access_logs_prefix" {
  type    = string
  default = "alb"
}

variable "access_logs_enabled" {
  type    = bool
  default = true
}

# --------------------
# Tags
# --------------------

variable "tags" {
  type    = map(string)
  default = {}
}

# --------------------
# Target Group
# --------------------

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
  default = "/health"
}

variable "health_check_protocol" {
  default = "HTTP"
}
