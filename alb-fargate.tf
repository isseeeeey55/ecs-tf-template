# ALB Setting
resource "aws_lb" "test-alb" {
  name                       = "${var.common["prefix"]}-${var.common["env"]}"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = module.main-vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.alb-sg.this_security_group_id
  ]

  tags = {
    Name = "${var.common["prefix"]}-${var.common["env"]}"
  }
}

# Listener Setting
resource "aws_lb_listener" "test-http" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test-tg.arn
    type             = "forward"
  }
}

# TargetGroup Setting
resource "aws_lb_target_group" "test-tg" {
  name     = "test-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id               = module.main-vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200"
  }
}