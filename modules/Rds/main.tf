terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.dr]
    }
  }
}


resource "aws_kms_key" "rds" {
  description = "RDS Encryption Key"
}

resource "aws_kms_key" "rds_dr" {
  count       = var.enable_cross_region_backup_replication ? 1 : 0
  provider    = aws.dr
  description = "DR RDS Key"
}

resource "aws_db_instance" "this" {

  identifier                          = var.identifier
  engine                              = var.engine
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  iam_database_authentication_enabled = true
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage

  db_name  = var.database_name
  username = var.username

  manage_master_user_password = true

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  multi_az = var.environment == "prod" ? true : false

  backup_retention_period = var.backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  blue_green_update {
    enabled = var.blue_green_update
  }

  performance_insights_enabled    = var.environment == "prod" ? true : false
  performance_insights_kms_key_id = var.environment == "prod" ? aws_kms_key.rds.arn : null

  #   monitoring_interval = 60

  delete_automated_backups = false

  deletion_protection = var.environment == "prod" ? true : false

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.identifier}-final-snapshot" : null

  enabled_cloudwatch_logs_exports = [
    "error",
    "general",
    "slowquery"
  ]

  tags = {
    Name        = var.identifier
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_db_snapshot" "example" {
  count                  = var.create_manual_snapshot ? 1 : 0
  db_instance_identifier = aws_db_instance.this.id
  db_snapshot_identifier = "${var.identifier}-manual-snapshot"
  lifecycle {
    ignore_changes = [
      db_snapshot_identifier # dont create a new snapshot on every changes
    ]
  }

}

# backup in "us-west-2"  region multi region replication
resource "aws_db_instance_automated_backups_replication" "auto_backups" {
  count                  = var.enable_cross_region_backup_replication ? 1 : 0
  provider               = aws.dr
  source_db_instance_arn = aws_db_instance.this.arn
  kms_key_id             = aws_kms_key.rds_dr[0].arn
  retention_period       = 14

}

resource "aws_db_subnet_group" "this" {
  name       = var.subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = var.identifier
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.identifier}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.identifier}-redis-subnet-group"
    Environment = var.environment
  }
}


resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.identifier}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_to_rds" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = var.app_security_group_id

  from_port   = var.rds_port_inbound
  to_port     = var.rds_port_inbound
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rds_outbound" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


resource "aws_security_group" "redis" {
  name        = "${var.identifier}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.identifier}-redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_to_redis" {

  security_group_id = aws_security_group.redis.id

  referenced_security_group_id = var.app_security_group_id

  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "redis_outbound" {

  security_group_id = aws_security_group.redis.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.environment}-redis"
  description          = "Production Redis"
  engine               = "redis"

  engine_version = var.engine_version_redis

  node_type = var.node_type

  num_cache_clusters = var.num_cache_clusters

  automatic_failover_enabled = var.environment == "prod" ? true : false

  multi_az_enabled = var.environment == "prod" ? true : false

  port = 6379

  at_rest_encryption_enabled = true

  transit_encryption_enabled = true

  auto_minor_version_upgrade = false

  subnet_group_name        = aws_elasticache_subnet_group.redis.name
  snapshot_retention_limit = 7
  snapshot_window          = "01:00-02:00"
  maintenance_window       = "sun:03:00-sun:04:00"
  security_group_ids = [
    aws_security_group.redis.id
  ]
}

# resource "aws_backup_plan" "rds" {
#   name = "rds-backup-plan"

#   rule {
#     rule_name         = "daily-backup"
#     target_vault_name = aws_backup_vault.rds.name
#     schedule          = "cron(0 2 * * ? *)" # 2 AM daily

#     lifecycle {
#       delete_after = 7
#     }
#   }
# }
