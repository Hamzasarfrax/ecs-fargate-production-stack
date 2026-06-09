variable "database_name" {
  type        = string
  description = "Name of the database"
  default     = "app-db"
}

variable "engine" {
  type        = string
  description = "Database engine"
  default     = "mysql"
}

variable "engine_version" {
  type        = string
  description = "Database engine version"
  default     = "8.4.8"
}

variable "instance_class" {
  type        = string
  description = "Database instance class"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in gigabytes"
  default     = 20
  validation {
    condition     = var.allocated_storage >= 10
    error_message = "Allocated storage must be at least 10 GB."
  }
}

variable "max_allocated_storage" {
  type        = number
  description = "The upper limit to which RDS can automatically scale the storage"
  default     = 100
  validation {
    condition     = var.max_allocated_storage >= var.allocated_storage
    error_message = "Max allocated storage must be greater than or equal to allocated storage."
  }
}

variable "username" {
  type        = string
  description = "Database username"
  default     = "db-username"
}

variable "multi_az" {
  type        = bool
  description = "Multi AZ"
  default     = true
}

variable "availability_zone" {
  type        = list(string)
  description = "Availability Zone"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "identifier" {
  type        = string
  description = "The name of the RDS instance"
  default     = "rds-instance"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period"
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 1
    error_message = "Backup retention period must be greater than or equal to 1."
  }

}

variable "blue_green_update" {
  type        = bool
  description = "Enable blue/green update"
  default     = true
}

variable "restore_to_point_in_time" {
  type        = bool
  description = "Restore to point in time"
  default     = true
}

variable "subnet_group_name" {
  type        = string
  description = "Name of the DB subnet group"
  default     = "main-db-subnet-group"
}

variable "private_subnet_range" {
  type        = list(string)
  description = "List of private subnet IDs for the RDS instance"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "vpc_id" {
  type        = string
  description = "VPC ID for RDS deployment"
  default     = "my-app"
}


variable "app_security_group_id" {
  type        = string
  description = "Security Group Id"
  default     = "sg-0abc123"
}

variable "create_manual_snapshot" {
  type        = bool
  default     = true
  description = "Manual snapshot"
}


variable "rds_port_inbound" {
  type        = number
  description = "Rds port number for inbound"
  default     = 3306
}


variable "engine_version_redis" {
  type        = string
  description = "Redis Version"
  default     = "7.1"
}

variable "node_type" {
  type        = string
  description = "Node Class Version"
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  type        = number
  default     = 2
  description = "Cache Cluster Number"
}
