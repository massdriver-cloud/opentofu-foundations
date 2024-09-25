output "instance_arn" {
  description = "AWS EC2 Instance ARN"
  value       = aws_instance.this.arn
}

output "instance_url" {
  description = "Public IP URL of the instance"
  value       = "http://${aws_instance.this.public_ip}"
}

output "rds_endpoint" {
  description = "MariaDB RDS Endpoint"
  value       = aws_db_instance.this.endpoint
}
