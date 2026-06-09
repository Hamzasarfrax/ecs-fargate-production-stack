variable "remote_table" {
  type    = string
  default = "remote_backend_table_lock"
}

variable "encrypt_remote_s3" {
  type    = string
  default = "true"
}

variable "repository_name" {
  type    = string
  default = "repository_image"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
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
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "Dev-project-aws"
}

variable "iam_groups" {
  description = "IAM groups for this environment."
  type = map(object({
    name                = string
    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), [])
  }))
  default = {
    developers = {
      name = "developers"
      path = "/dev/"
    }
    production = {
      name = "production"
      path = "/prod/"
    }
    security = {
      name = "security"
      path = "/security/"
    }
  }
}

variable "iam_roles" {
  description = "IAM roles for this environment."
  type = map(object({
    name                    = string
    description             = optional(string, null)
    path                    = optional(string, "/")
    trusted_services        = list(string)
    managed_policy_arns     = optional(list(string), [])
    max_session_duration    = optional(number, 3600)
    create_instance_profile = optional(bool, false)
  }))
  default = {
    ec2_ssm = {
      name                    = "dev-ec2-ssm-role"
      description             = "Allows EC2 instances to use AWS Systems Manager."
      path                    = "/service/"
      trusted_services        = ["ec2.amazonaws.com"]
      managed_policy_arns     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
      create_instance_profile = true
    }
  }
}



# for vpc

variable "nat_gateway_strategy" {
  type    = string
  default = "single"

  validation {
    condition = contains(
      ["single", "one_per_az", "none"],
      var.nat_gateway_strategy
    )

    error_message = "nat_gateway_strategy must be single, one_per_az, or none."
  }
}
