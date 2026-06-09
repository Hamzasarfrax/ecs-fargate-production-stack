output "aws_sns_topic" {
  value = aws_sns_topic.alerts.arn
}

output "aws_cloudwatch_dashboard" {
  value = aws_cloudwatch_dashboard.main
}

output "aws_cloudwatch_event_rule" {
  value = aws_cloudwatch_event_rule.root_login
}

output "aws_cloudwatch_event_target" {
  value = aws_cloudwatch_event_target.sns
}

output "aws_cloudwatch_metric_alarm" {
  value = aws_cloudwatch_metric_alarm
}

output "aws_cloudwatch_metric_alarm_rds" {
  value = aws_cloudwatch_metric_alarm.rds_cpu
}


output "aws_sns_topic_subscription" {
  value = aws_sns_topic_subscription.email
}
