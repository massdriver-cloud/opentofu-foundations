output "endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.this.endpoint
}

output "username" {
  description = "Database master username"
  value       = aws_db_instance.this.username
}

output "password" {
  description = "Database master password"
  value       = aws_db_instance.this.password
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.this.id
}
