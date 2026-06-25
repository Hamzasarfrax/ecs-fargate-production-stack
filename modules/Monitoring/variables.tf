variable "service_name" {
  type    = string
  default = "dev"
}

variable "sns_topic_arn" {
  type        = string
  description = "Existing SNS topic ARN. If null, internal topic will be used."
  default     = null
}

variable "ecs_cpu_threshold" {
  type    = number
  default = 80
}

variable "ecs_memory_threshold" {
  type    = number
  default = 80
}

variable "alb_5xx_threshold" {
  type    = number
  default = 10
}

variable "rds_cpu_threshold" {
  type    = number
  default = 75
}

variable "email" {
  type    = string
  default = "test@gmail.com"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "db_instance_id" {
  type    = string
  default = "dev-db"
}

variable "cluster_name" {
  type    = string
  default = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "alb_arn_suffix" {
  type    = string
  default = "dev"
}
