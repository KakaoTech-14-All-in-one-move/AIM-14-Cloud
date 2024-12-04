# 이전 코드는 동일하게 유지하고, 다음 내용을 추가합니다...

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.pitching_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

# Application Load Balancer
resource "aws_lb" "be_alb" {
  name               = "be-alb"
  internal           = true  # 내부 ALB (private subnet에서만 접근 가능)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.be_subnet_private.id, aws_subnet.ai_subnet_private_1.id]  # 최소 2개의 서브넷 필요

  enable_deletion_protection = false  # 프로덕션에서는 true 권장

  tags = {
    Name = "be-alb"
  }
}

# Target Groups
resource "aws_lb_target_group" "be_blue" {
  name     = "be-blue-tg"
  port     = 8080  # 백엔드 애플리케이션 포트
  protocol = "HTTP"
  vpc_id   = aws_vpc.pitching_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher            = "200"
    path               = "/health"  # 헬스 체크 엔드포인트
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "be-blue-tg"
  }
}

resource "aws_lb_target_group" "be_green" {
  name     = "be-green-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.pitching_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "be-green-tg"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "be_blue" {
  target_group_arn = aws_lb_target_group.be_blue.arn
  target_id        = aws_instance.be_server_blue.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "be_green" {
  target_group_arn = aws_lb_target_group.be_green.arn
  target_id        = aws_instance.be_server_green.id
  port             = 8080
}

# ALB Listener
resource "aws_lb_listener" "be_listener" {
  load_balancer_arn = aws_lb.be_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.be_blue.arn  # 기본적으로 blue로 트래픽 전달
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "pitching-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.be_alb.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTP_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = "ap-northeast-2"
          title  = "ALB Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.be_server_blue.id],
            [".", ".", ".", aws_instance.be_server_green.id]
          ]
          period = 300
          stat   = "Average"
          region = "ap-northeast-2"
          title  = "BE Servers CPU Utilization"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu_blue" {
  alarm_name          = "high-cpu-be-blue"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors BE blue server CPU utilization"
  alarm_actions      = []  # SNS topic ARN을 추가하여 알림 설정 가능

  dimensions = {
    InstanceId = aws_instance.be_server_blue.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_green" {
  alarm_name          = "high-cpu-be-green"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors BE green server CPU utilization"
  alarm_actions      = []  # SNS topic ARN을 추가하여 알림 설정 가능

  dimensions = {
    InstanceId = aws_instance.be_server_green.id
  }
}

# BE 서버 보안 그룹 인바운드 규칙 추가 (기존 private_sg에 추가)
resource "aws_security_group_rule" "be_alb_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.private_sg.id
  description             = "Allow traffic from ALB"
}