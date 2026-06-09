output "service_name" {
  value       = aws_ecs_service.this.name
  description = "The ECS service name."
}

output "service_id" {
  value       = aws_ecs_service.this.id
  description = "The ECS service ID."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "The ECS task definition ARN."
}

output "task_definition_family" {
  value       = aws_ecs_task_definition.this.family
  description = "The ECS task definition family."
}

output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "The CloudWatch log group name."
}

output "autoscaling_target_resource_id" {
  value       = try(aws_appautoscaling_target.ecs[0].resource_id, null)
  description = "The Application Auto Scaling target resource ID."
}
