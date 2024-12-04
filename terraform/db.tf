# PostgreSQL Server
resource "aws_instance" "postgresql_server" {
  ami           = "ami-062cf18d655c0b1e8" # Ubuntu 20.04 LTS AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.be_subnet_private.id
  key_name      = "aim"
  security_groups = [aws_security_group.pg_sg.id]

  # ansible 포기
  user_data = <<-EOT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
  EOT

  tags = {
    Name = "PostgreSQL-Server"
  }
}

# Redis Server
resource "aws_instance" "redis_server" {
  ami           = "ami-062cf18d655c0b1e8" # Ubuntu 20.04 LTS AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.be_subnet_private.id
  key_name      = "aim"
  security_groups = [aws_security_group.redis_sg.id]

  # ansible 포기
  user_data = <<-EOT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
  EOT

  tags = {
    Name = "Redis-Server"
  }
}

# RabbitMQ Server
resource "aws_instance" "rabbitmq_server" {
  ami           = "ami-062cf18d655c0b1e8" # Ubuntu 20.04 LTS AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.be_subnet_private.id
  key_name      = "aim"
  security_groups = [aws_security_group.rmq_sg.id]

  # ansible 포기
  user_data = <<-EOT
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y rabbitmq-server
    sudo systemctl enable rabbitmq-server
    sudo systemctl start rabbitmq-server

    # RabbitMQ Management Plugin 활성화
    sudo rabbitmq-plugins enable rabbitmq_management
    sudo systemctl restart rabbitmq-server
  EOT

  tags = {
    Name = "RabbitMQ-Server"
  }
}