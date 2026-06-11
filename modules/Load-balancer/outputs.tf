output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ECS Service ko is ARN ki zaroori hoti hai traffic receive karne ke liye"
  value       = aws_lb_target_group.this.arn
}
