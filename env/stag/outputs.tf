output "iam_group_names" {
  description = "IAM group names created in dev."
  value       = module.iam.group_names
}

output "iam_role_arns" {
  description = "IAM role ARNs created in dev."
  value       = module.iam.role_arns
}

output "iam_instance_profile_names" {
  description = "IAM instance profiles created in dev."
  value       = module.iam.instance_profile_names
}

# ====================================================
# Network Outputs
# ====================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR Block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ====================================================
# Load Balancer Outputs
# ====================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.load_balancer.alb_arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.load_balancer.target_group_arn
}

# ====================================================
# ECS Outputs
# ====================================================

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = try(module.ecs.service_name, "Not yet deployed")
}

# ====================================================
# Database & Cache Outputs
# ====================================================

output "rds_endpoint" {
  description = "RDS Database Endpoint"
  value       = try(module.rds.db_instance_endpoint, "Not yet deployed")
  sensitive   = false
}

output "redis_endpoint" {
  description = "Redis Cluster Endpoint for Caching (80x faster reads!)"
  value       = try(module.rds.redis_endpoint, "Not yet deployed")
  sensitive   = false
}

# ====================================================
# ECR Outputs
# ====================================================

output "ecr_repository_url" {
  description = "ECR Repository URL for pushing images"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = module.ecr.repository_arn
}

# ====================================================
# Security Groups
# ====================================================

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS Task Security Group ID"
  value       = aws_security_group.ecs.id
}

# ====================================================
# IAM Roles
# ====================================================

output "ecs_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

