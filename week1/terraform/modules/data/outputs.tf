output "db_endpoint" {
  value = aws_db_instance.app.endpoint
}

output "db_id" {
  value = aws_db_instance.app.id
}
