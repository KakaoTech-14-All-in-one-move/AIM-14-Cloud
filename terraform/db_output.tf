# PostgreSQL Server Private IP
output "pg_server_ip" {
  value       = aws_instance.postgresql_server.private_ip
  description = "PostgreSQL 서버의 Private IP"
}

# Redis Server Private IP
output "redis_server_ip" {
  value       = aws_instance.redis_server.private_ip
  description = "Redis 서버의 Private IP"
}

# RabbitMQ Server Private IP
output "rmq_server_ip" {
  value       = aws_instance.rabbitmq_server.private_ip
  description = "RabbitMQ 서버의 Private IP"
}

# Bastion Host (FE 서버) Public IP
output "bastion_public_ip" {
  value       = aws_instance.fe_server.public_ip
  description = "FE 서버의 Public IP (Bastion Host)"
}