# 사용하고자 하는 AWS 리전: 서울
provider "aws" {
  region = "ap-northeast-2"
}

# VPC 설정
resource "aws_vpc" "pitching_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "pitching_vpc"
  }
}

# Subnet 설정
resource "aws_subnet" "fe_subnet_public" {
  vpc_id                  = aws_vpc.pitching_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "fe_subnet_public"
  }
}

resource "aws_subnet" "be_subnet_private" {
  vpc_id            = aws_vpc.pitching_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "be_subnet_private"
  }
}

resource "aws_subnet" "ai_subnet_private_1" {
  vpc_id            = aws_vpc.pitching_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ai_subnet_private_1"
  }
}

resource "aws_subnet" "ai_subnet_private_2" {
  vpc_id            = aws_vpc.pitching_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "ai_subnet_private_2"
  }
}

# Internet Gateway 설정
resource "aws_internet_gateway" "pitching_igw" {
  vpc_id = aws_vpc.pitching_vpc.id

  tags = {
    Name = "pitching_igw"
  }
}

# NAT Instance 설정
resource "aws_instance" "nat_instance" {
  ami           = "ami-0e7750a7f051bb3ac"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.fe_subnet_public.id
  associate_public_ip_address = true
  source_dest_check = false
  key_name = "aim"
  security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "NAT-Instance"
  }
}

# Route Tables 설정
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pitching_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pitching_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.fe_subnet_public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.pitching_vpc.id

  route {
    cidr_block  = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }

  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "private_rt_assoc_be" {
  subnet_id      = aws_subnet.be_subnet_private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_ai_1" {
  subnet_id      = aws_subnet.ai_subnet_private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_ai_2" {
  subnet_id      = aws_subnet.ai_subnet_private_2.id
  route_table_id = aws_route_table.private_rt.id
}


# Security Groups 설정
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.pitching_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "public_sg" }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.pitching_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "private_sg" }
}

# EC2 Instances 설정
# Jenkins Server (Public Subnet)
resource "aws_instance" "jenkins_server" {
  ami           = "ami-062cf18d655c0b1e8" # Jenkins가 설치 가능한 AMI
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fe_subnet_public.id
  associate_public_ip_address = true
  key_name      = "aim"
  security_groups = [aws_security_group.public_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              docker run -d -p 8080:8080 jenkins/jenkins:lts
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

# FE Server (Public)
resource "aws_instance" "fe_server" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.fe_subnet_public.id
  key_name = "aim"
  security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "FE-Server"
  }
}

# BE Server 1 (Blue Deployment in Private Subnet)
resource "aws_instance" "be_server_blue" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.be_subnet_private.id
  key_name = "aim"
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "BE-Server-Blue"
  }
}

# BE Server 2 (Green Deployment in Private Subnet)
resource "aws_instance" "be_server_green" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.be_subnet_private.id
  key_name = "aim"
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "BE-Server-Green"
  }
}

# AI Server 1 (Private Subnet in AZ 1)
resource "aws_instance" "ai_server_1" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ai_subnet_private_1.id
  key_name = "aim"
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "AI-Server-1"
  }
}

# AI Server 2 (Private Subnet in AZ 2)
resource "aws_instance" "ai_server_2" {
  ami           = "ami-062cf18d655c0b1e8"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.ai_subnet_private_2.id
  key_name = "aim"
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "AI-Server-2"
  }
}

# ECR for Docker images (optional)
resource "aws_ecr_repository" "pitching_repo" {
  name = "pitching_repo"
}