variable "name" {
  description = "Project name"
  type        = string
  default     = "my-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be valid CIDR."
  }
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "public_subnets" {
  description = "Public subnets"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    public_a = {
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
    }
    public_b = {
      cidr = "10.0.2.0/24"
      az   = "us-east-1b"
    }
    public_c = {
      cidr = "10.0.3.0/24"
      az   = "us-east-1c"
    }
  }

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "At least one public subnet required."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.public_subnets) :
      can(cidrhost(subnet.cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid."
  }
}

variable "private_subnets" {
  description = "Private subnets"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    private_a = {
      cidr = "10.0.4.0/24"
      az   = "us-east-1a"
    }
    private_b = {
      cidr = "10.0.5.0/24"
      az   = "us-east-1b"
    }
    private_c = {
      cidr = "10.0.6.0/24"
      az   = "us-east-1c"
    }
  }

  validation {
    condition = alltrue([
      for subnet in values(var.private_subnets) :
      can(cidrhost(subnet.cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid."
  }
}

variable "nat_gateway_strategy" {
  description = "NAT strategy"
  type        = string
  default     = "single"

  validation {
    condition = contains(
      ["single", "one_per_az", "none"],
      var.nat_gateway_strategy
    )

    error_message = "nat_gateway_strategy must be single, one_per_az, or none."
  }
}

variable "create_public_nacl" {
  type    = bool
  default = false
}

variable "enable_vpc_endpoints" {
  description = "Create private VPC endpoints so private workloads can reach AWS services without a NAT gateway."
  type        = bool
  default     = true
}

variable "gateway_endpoint_services" {
  description = "Gateway endpoints attached to private route tables."
  type        = set(string)
  default     = ["s3", "dynamodb"]
}

variable "interface_endpoint_services" {
  description = "Interface endpoints used by ECS tasks and application workloads in private subnets."
  type        = set(string)
  default = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "ec2messages"
  ]
}

variable "tags" {
  type    = map(string)
  default = {}
}
