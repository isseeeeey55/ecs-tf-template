## IAM Role Module
data "aws_iam_policy" "ecs_instance_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_instance" {
  source_json = data.aws_iam_policy.ecs_instance_role_policy.policy
}

module "ecs_instance_role" {
  source     = "./iam_role"
  name       = "ecs-instance-role"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_instance.json
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy
}

module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile"
  path = "/"
  role = module.ecs_instance_role.iam_role_id
}

## ECS-EC2
resource "aws_instance" "ec2_instance" {
  ami                  = "ami-03003e0e2f7489bfa" # AmazonLinux2 ap-northeast-1 AMI
  subnet_id            = element(module.main-vpc.private_subnets, index(var.zones, "ap-northeast-1a"))
  instance_type        = "t2.medium"
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.name

  vpc_security_group_ids = [
    module.nginx-sg.this_security_group_id
  ]

  key_name          = var.common["key_name"]
  ebs_optimized     = "false"
  source_dest_check = "false"
  user_data         = data.template_file.user_data.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }

  tags = {
    Name = "${var.common["prefix"]}-${var.common["env"]}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"
}

# Task-Definition
resource "aws_ecs_task_definition" "test-taskdefinition-ec2" {
  family                   = "${var.common["prefix"]}-test"
  network_mode             = "awsvpc"
  memory                   = "2048"
  cpu                      = "1024"
  requires_compatibilities = ["EC2"]
  container_definitions    = file("./container_definitions_ec2.json")
  task_role_arn            = module.ecs_task_execution_role.iam_role_arn
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

# ECS-Service
resource "aws_ecs_service" "test-service-ec2" {
  name             = "${var.common["prefix"]}-test"
  cluster          = aws_ecs_cluster.test-cluster.arn
  task_definition  = aws_ecs_task_definition.test-taskdefinition-ec2.arn
  desired_count    = 1
  launch_type      = "EC2"
  # platform_version = ""
  # health_check_grace_period_seconds = 60

  network_configuration {
    # assign_public_ip = false
    security_groups = [
      module.nginx-sg.this_security_group_id,
    ]

    subnets = module.main-vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.test-tg-ec2.arn
    container_name   = "${var.common["prefix"]}-${var.common["env"]}-ec2"
    container_port   = 80
  }

  # lifecycle {
  #   ignore_changes = [
  #     task_definition,
  #   ]
  # }

  depends_on = [aws_lb_listener.test-http-ec2]
}

## CloudWatch Logs
resource "aws_cloudwatch_log_group" "test-log-ec2" {
  name              = "/ecs/${var.common["prefix"]}-${var.common["env"]}"
  retention_in_days = 180
}