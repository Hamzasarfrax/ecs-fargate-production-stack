output "aws_sns_topic" {
  value = aws_sns_topic.alerts.arn
}

output "aws_cloudwatch_dashboard" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "aws_cloudwatch_event_rule" {
  value = aws_cloudwatch_event_rule.root_login.name
}

output "aws_cloudwatch_event_target" {
  value = aws_cloudwatch_event_target.sns.target_id
}

output "aws_cloudwatch_metric_alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_memory_high.alarm_name,
    aws_cloudwatch_metric_alarm.alb_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.alb_latency.alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
  ]
}

output "aws_cloudwatch_metric_alarm_rds" {
  value = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
}


output "aws_sns_topic_subscription" {
  value = aws_sns_topic_subscription.email.arn
}
