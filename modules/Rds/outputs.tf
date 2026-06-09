output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}
output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "secret_arn" {
  value     = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive = true
}

# output "db_security_group_id" {
#   value = aws_security_group.rds.id
# }
