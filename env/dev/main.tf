
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform-Dev"
    Owner       = "DevOps-Team"
  }
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

module "iam" {
  source = "../../modules/Iam"

  # groups = var.iam_groups
  # roles  = var.iam_roles
  # tags   = merge(local.common_tags, var.tags)
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

  nat_gateway_strategy = "single"
  create_public_nacl   = false

  tags = merge(local.common_tags, var.tags)
}




#ecs module

module "ecs" {
  source = "../../modules/Ecs"

  aws_region      = var.environment.region
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
  target_group_arn   = aws_lb_target_group.app.arn

  enable_blue_green = false

  tags = merge(local.common_tags, var.tags)
}


# module of rds 

module "rds" {
  source = "../../modules/rds"

  environment           = var.environment
  identifier            = var.project_name
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
  vpc_id                = module.vpc.vpc_id
  app_security_group_id = module.ecs.ecs_sg_id
}




# module cloudwatch

module "cloudwatch" {
  source = "./modules/cloudwatch"

  service_name   = "payment-api"
  cluster_name   = "prod-cluster"
  db_instance_id = "prod-db-1"
  alb_arn_suffix = "app/my-alb/123456"

  sns_topic_arn = module.sns.topic_arn

  ecs_cpu_threshold    = 80
  ecs_memory_threshold = 80
  alb_5xx_threshold    = 10
  rds_cpu_threshold    = 75
}
