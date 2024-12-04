# PostgreSQL 보안 그룹
resource "aws_security_group" "pg_sg" {
  name        = "PostgreSQL_SG"
  description = "PostgreSQL security group"
  vpc_id      = aws_vpc.pitching_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC 내부 통신 허용
  }

  ingress {
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_groups = [aws_security_group.public_sg.id]  # 베스천 호스트의 보안 그룹 ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PostgreSQL_SG"
  }
}


# Redis 보안 그룹
resource "aws_security_group" "redis_sg" {
  name        = "Redis_SG"
  description = "Redis security group"
  vpc_id      = aws_vpc.pitching_vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC 내부 통신 허용
  }

  ingress {
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_groups = [aws_security_group.public_sg.id]  # 베스천 호스트의 보안 그룹 ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Redis_SG"
  }
}


# RabbitMQ 보안 그룹
resource "aws_security_group" "rmq_sg" {
  name        = "RabbitMQ_SG"
  description = "RabbitMQ security group"
  vpc_id      = aws_vpc.pitching_vpc.id

  # 포트 5672 (AMQP) 허용
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC 내부 통신 허용
  }

  # 포트 15672 (Management Plugin) 허용
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC 내부 통신 허용
  }

  ingress {
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_groups = [aws_security_group.public_sg.id]  # 베스천 호스트의 보안 그룹 ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RabbitMQ_SG"
  }
}
