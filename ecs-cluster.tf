## ECS Cluster
resource "aws_ecs_cluster" "test-cluster" {
  name = "${var.common["prefix"]}-${var.common["env"]}-cluster"
}