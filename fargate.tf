## IAM Role Module
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

## Task Definition
resource "aws_ecs_task_definition" "test-taskdefinition" {
  family                   = "${var.common["prefix"]}-${var.common["env"]}"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

## ECS Service
resource "aws_ecs_service" "test-service" {
  name                              = "${var.common["prefix"]}-${var.common["env"]}"
  cluster                           = aws_ecs_cluster.test-cluster.arn
  task_definition                   = aws_ecs_task_definition.test-taskdefinition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups = [
      module.nginx-sg.this_security_group_id,
    ]

    subnets = module.main-vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.test-tg.arn
    container_name   = "${var.common["prefix"]}-${var.common["env"]}"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  depends_on = [aws_lb_listener.test-http]
}

## CloudWatch Logs
resource "aws_cloudwatch_log_group" "test-log" {
  name              = "/ecs/${var.common["prefix"]}-${var.common["env"]}"
  retention_in_days = 180
}