terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# 1. CLOUDWATCH LOG GROUP
# Stores application logs written by the ECS container through the awslogs driver.
# Retention is configurable so each environment can balance cost and compliance needs.
# kms_key_id is optional; provide a KMS key ARN when logs must be encrypted with a customer-managed key.
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_arn

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

#cluster

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}
# --------------------------------------------------------------------------------------------------
# 2. ECS TASK DEFINITION
# Defines the runtime blueprint for the container: Docker image, CPU, memory, exposed port,
# IAM roles, environment variables, secrets, and CloudWatch logging configuration.
# Fargate requires awsvpc network mode, which gives each task its own elastic network interface.
# --------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = var.environment_variables
      secrets     = var.secrets
    }
  ])

  tags = var.tags
}

# --------------------------------------------------------------------------------------------------
# 3. ECS SERVICE
# Keeps the requested number of tasks running and attaches them to the load balancer.
# Tasks run in private subnets with no public IP address; inbound traffic should come through the ALB.
# Blue/green uses CodeDeploy as the deployment controller, while normal deployments use ECS rolling updates.
# --------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count


  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 2
  }

  enable_execute_command = var.enable_execute_command

  deployment_controller {
    type = var.enable_blue_green ? "CODE_DEPLOY" : "ECS"
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_blue_green ? [] : [1]

    content {
      enable   = true
      rollback = true
    }
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# --------------------------------------------------------------------------------------------------
# 4. APPLICATION AUTOSCALING
# Registers the ECS service with Application Auto Scaling.
# When enabled, AWS adjusts desired_count based on average ECS service CPU utilization.
# desired_count is ignored in the ECS service lifecycle because autoscaling owns that value after deploy.
# --------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "ecs" {
  count              = var.enable_autoscaling ? 1 : 0
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.cpu_autoscaling_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}



resource "aws_appautoscaling_policy" "memory" {

  count = var.enable_autoscaling ? 1 : 0
  name  = "${var.service_name}-memory-scaling"

  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = var.memory_autoscaling_target_value

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
# --------------------------------------------------------------------------------------------------
# 5. BLUE/GREEN DEPLOYMENT
# Optional CodeDeploy setup for ECS blue/green releases.
# This requires an ALB listener, two target groups, and a CodeDeploy service role.
# It is disabled by default because rolling deployments are simpler and require fewer dependencies.
# --------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "codedeploy" {
  name = "${var.service_name}-codedeploy-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.codedeploy.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.service_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_sns_topic.codedeploy.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.service_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_sns_topic.codedeploy.arn]
}


resource "aws_codedeploy_app" "ecs" {
  count            = var.enable_blue_green ? 1 : 0
  compute_platform = "ECS"
  name             = "${var.service_name}-app"
}


resource "aws_codedeploy_deployment_group" "ecs" {
  count                 = var.enable_blue_green ? 1 : 0
  app_name              = aws_codedeploy_app.ecs[0].name
  deployment_group_name = "${var.service_name}-dg"

  service_role_arn       = var.codedeploy_role_arn
  deployment_config_name = var.deployment_config_name

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = aws_ecs_service.this.name
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  #  AUTO ROLLBACK (CORRECT)
  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_ALARM"
    ]
  }

  #  SNS TRIGGERS (GOOD FOR NOTIFICATIONS ONLY)
  trigger_configuration {
    trigger_name = "${var.service_name}-trigger"

    trigger_events = [
      "DeploymentFailure",
      "DeploymentStop",
      "DeploymentRollback"
    ]

    trigger_target_arn = aws_sns_topic.codedeploy.arn
  }

  #  ALARM BASED ROLLBACK (IMPORTANT)
  alarm_configuration {
    enabled = true

    alarms = [
      aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
      aws_cloudwatch_metric_alarm.memory_high.alarm_name
    ]
  }

  load_balancer_info {
    target_group_pair_info {

      prod_traffic_route {
        listener_arns = [var.listener_arn]
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }

  lifecycle {
    precondition {
      condition = !var.enable_blue_green || (
        var.codedeploy_role_arn != null &&
        var.listener_arn != null &&
        var.blue_target_group_name != null &&
        var.green_target_group_name != null
      )

      error_message = "Blue/Green enabled hai to sare required inputs mandatory hain."
    }
  }
}
