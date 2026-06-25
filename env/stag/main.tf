
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps-Team"
  }
}

# ====================================================
# Security Groups for ALB and ECS
# ====================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-ecs-sg" })
}

# ====================================================
# IAM Roles for ECS
# ====================================================

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "${var.project_name}-ecs-execution-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Name = "${var.project_name}-ecs-task-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_ecr_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "iam" {
  source = "../../modules/Iam"

  name = {
    name = "${var.project_name}-${var.environment}-iam"
  }

  env = {
    name    = var.project_name
    env     = var.environment
    tagname = "${var.project_name}-${var.environment}"
  }

  ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
}



# vpc module 

module "vpc" {
  source = "../../modules/Vpc"

  name        = var.project_name
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"

  public_subnets = {
    public_a = {
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
    }
    public_b = {
      cidr = "10.0.2.0/24"
      az   = "us-east-1b"
    }
  }

  private_subnets = {
    private_a = {
      cidr = "10.0.11.0/24"
      az   = "us-east-1a"
    }
    private_b = {
      cidr = "10.0.12.0/24"
      az   = "us-east-1b"
    }
  }

  nat_gateway_strategy = var.nat_gateway_strategy
  enable_vpc_endpoints = true
  create_public_nacl   = false

  tags = merge(local.common_tags, var.tags)
}


# load balancer module 

module "load_balancer" {
  source                     = "../../modules/Load-balancer"
  name                       = "${var.project_name}-alb"
  internal                   = false
  subnets                    = module.vpc.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  vpc_id                     = module.vpc.vpc_id
  tg_name                    = "${var.project_name}-tg"
  certificate_arn            = var.certificate_arn
  access_logs_bucket         = var.alb_access_logs_bucket
  access_logs_enabled        = var.alb_access_logs_bucket != null
  enable_deletion_protection = var.environment == "prod"
  enable_waf                 = true
  tags                       = merge(local.common_tags, var.tags)
}

# cloudfront module
module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "../../modules/Cloudfront"

  name                = "${var.project_name}-${var.environment}"
  origin_domain_name  = module.load_balancer.alb_dns_name
  origin_id           = "${var.project_name}-alb-origin"
  aliases             = var.cloudfront_aliases
  acm_certificate_arn = var.cloudfront_certificate_arn
  logging_bucket      = var.cloudfront_logging_bucket

  tags = merge(local.common_tags, var.tags)
}

# the ecr module
module "ecr" {
  source               = "../../modules/Ecr"
  repository_name      = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push
  kms_key_arn          = var.kms_key_arn
  tags                 = merge(local.common_tags, var.tags)
}

#ecs module
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, var.tags)
}

module "ecs" {
  source = "../../modules/Ecs"

  aws_region      = var.aws_region
  environment     = var.environment
  service_name    = "my-app"
  cluster_name    = aws_ecs_cluster.main.name
  cluster_arn     = aws_ecs_cluster.main.arn
  container_image = "nginx:latest"
  container_port  = 80

  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = aws_security_group.ecs.id

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  target_group_arn   = module.load_balancer.target_group_arn

  enable_blue_green  = false
  enable_autoscaling = true

  tags = merge(local.common_tags, var.tags)
}


# module of rds 

module "rds" {
  source = "../../modules/Rds"

  providers = {
    aws.dr = aws.dr
  }

  environment           = var.environment
  identifier            = var.project_name
  private_subnet_ids    = module.vpc.private_subnet_ids
  vpc_id                = module.vpc.vpc_id
  app_security_group_id = aws_security_group.ecs.id
}
# module cloudwatch

module "cloudwatch" {
  source = "../../modules/Monitoring"

  env            = var.environment
  service_name   = "my-app"
  cluster_name   = aws_ecs_cluster.main.name
  db_instance_id = module.rds.db_instance_id
  alb_arn_suffix = module.load_balancer.alb_arn_suffix

  sns_topic_arn = null # Will create internal topic
  email         = var.alert_email

  ecs_cpu_threshold    = 80
  ecs_memory_threshold = 80
  alb_5xx_threshold    = 10
  rds_cpu_threshold    = 75
}
