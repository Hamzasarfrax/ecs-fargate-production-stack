variable "aws_region" {
  type        = string
  description = "AWS region jahan resources deploy honge."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name, e.g. dev, stage, prod."
}

variable "service_name" {
  type        = string
  description = "Application ya service ka naam (e.g., payment-api)."
  default     = "test-service"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster ka naam jahan service chalegi."
  default     = "test-cluster"
}

variable "cluster_arn" {
  type        = string
  description = "ECS cluster ka ARN."
  default     = "arn:aws:ecs:us-east-1:123456789012:cluster/test-cluster"
}

variable "container_image" {
  type        = string
  description = "Docker image ka URI (ECR ya DockerHub)."
  default     = "nginx:latest"
}

variable "container_port" {
  type        = number
  description = "Application jis port par listen kar rahi hai."
  default     = 80
}

variable "cpu" {
  type        = number
  default     = 256
  description = "vCPU units (256 = 0.25 vCPU)"

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "Enterprise Error: Fargate CPU value valid honi chahiye (256, 512, 1024, etc.)."
  }
}

variable "memory" {
  type        = number
  default     = 512
  description = "Memory (MBs mein)."
  validation {
    condition     = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, 16384, 30720], var.memory)
    error_message = "memory must be a valid Fargate memory value, e.g. 512, 1024, 2048, 4096, 8192, 16384, or 30720."
  }
}

variable "desired_count" {
  type        = number
  default     = 2
  description = "Minimum running containers kitne hone chahiye hamesha."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs jahan ECS tasks run honge, e.g. module.vpc.private_subnet_ids."
  default     = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

variable "ecs_sg_id" {
  type        = string
  description = "Security Group ID jo ECS tasks par lagega."
  default     = "sg-0123456789abcdef0"
}

variable "execution_role_arn" {
  type        = string
  description = "IAM Role ARN jo ECS Agent ko ECR se image pull karne aur CloudWatch mein logs bhejne ke liye chahiye."
  default     = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
}

variable "task_role_arn" {
  type        = string
  description = "IAM Role ARN jo actual container ke andar chalne wale code ko AWS resources (S3, RDS) use karne ki permission deta hai."
  default     = "arn:aws:iam::123456789012:role/ecsTaskRole"
}

variable "target_group_arn" {
  type        = string
  description = "Primary Load Balancer Target Group ARN."
  default     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-target-group/0123456789abcdef"
}

variable "log_retention_in_days" {
  type        = number
  default     = 90
  description = "Enterprise Compliance ke liye logs kitne din tak save rakhne hain."
}

variable "enable_execute_command" {
  type        = bool
  default     = true
  description = "ECS Exec enable karta hai taake debugging ke liye container ke andar command run kar sako."
}

variable "health_check_grace_period_seconds" {
  type        = number
  default     = 60
  description = "Load balancer health checks start hone se pehle app ko warm-up time."
}

variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Non-sensitive config variables."
}

variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default     = []
  description = "Sensitive credentials (AWS Secrets Manager ya SSM Parameter Store se)."
}

# --- Deployment / Strategy Flags ---
variable "enable_blue_green" {
  type        = bool
  default     = false
  description = "Agar true hoga toh CodeDeploy Blue/Green set up hoga, warna standard Rolling Update."
}

variable "deployment_config_name" {
  type        = string
  default     = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
  description = "Blue/Green traffic shifting strategy."
}

variable "listener_arn" {
  type        = string
  default     = null
  description = "Production Application Load Balancer Listener ARN (Blue/Green ke liye zaroori)."
}

variable "blue_target_group_name" {
  type        = string
  default     = null
  description = "Blue Target Group ka naam."
}

variable "green_target_group_name" {
  type        = string
  default     = null
  description = "Green Target Group ka naam."
}

variable "codedeploy_role_arn" {
  type        = string
  default     = null
  description = "CodeDeploy service ka IAM role."
}

# --- Autoscaling ---
variable "enable_autoscaling" {
  type    = bool
  default = true
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 10
}

variable "cpu_autoscaling_target_value" {
  type    = number
  default = 70

  validation {
    condition     = var.cpu_autoscaling_target_value > 0 && var.cpu_autoscaling_target_value <= 100
    error_message = "cpu_autoscaling_target_value 1 se 100 ke beech hona chahiye."
  }
}

variable "memory_autoscaling_target_value" {
  type    = number
  default = 70

  validation {
    condition     = var.memory_autoscaling_target_value > 0 && var.memory_autoscaling_target_value <= 100
    error_message = "memory_autoscaling_target_value 1 se 100 ke beech hona chahiye."
  }
}



variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_kms_key_arn" {
  type    = string
  default = null
}


variable "alert_email" {
  type    = string
  default = "salma@salmatextiles.com"
}
