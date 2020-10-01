## ALB Setting
resource "aws_lb" "test-alb-ec2" {
  name                       = "${var.common["prefix"]}-${var.common["env"]}-ec2"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = module.main-vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.ec2_alb_log.id
    enabled = true
  }

  security_groups = [
    module.alb-sg.this_security_group_id
  ]

  tags = {
    Name = "${var.common["prefix"]}-${var.common["env"]}-ec2"
  }
}

## Listener Setting
resource "aws_lb_listener" "test-http-ec2" {
  load_balancer_arn = aws_lb.test-alb-ec2.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test-tg-ec2.arn
    type             = "forward"
  }
}

## TargetGroup Setting
resource "aws_lb_target_group" "test-tg-ec2" {
  name     = "test-tg-ec2"
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
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200"
  }
}

## Attach TargetGroup Setting
resource "aws_lb_target_group_attachment" "test-tg-ec2-attach" {
  target_group_arn = aws_lb_target_group.test-tg-ec2.arn
  target_id        = aws_instance.ec2_instance.id
  port             = 80
}