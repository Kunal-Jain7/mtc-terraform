locals {
  ecr_url   = aws_ecr_repository.client-ecr-repo.repository_url
  ecr_token = data.aws_ecr_authorization_token.ecr-token
}
data "aws_ecr_authorization_token" "ecr-token" {}

resource "aws_ecr_repository" "client-ecr-repo" {
  name         = "var.ecr_repository_name"
  force_delete = true
}

resource "terraform_data" "docker-login" {
  provisioner "local-exec" {
    command = <<EOT
    docker login ${local.ecr_url} --username ${local.ecr_token.user_name} --password ${local.ecr_token.password}
    EOT
  }
}

resource "terraform_data" "docker-build" {
  depends_on = [terraform_data.docker-login]
  provisioner "local-exec" {
    command = <<EOT
    docker build -t ${local.ecr_url} ${path.module}/application/${var.app_name}
    EOT
  }
}

resource "terraform_data" "docker-push" {
  triggers_replace = [
    var.image_version
  ]
  depends_on = [terraform_data.docker-login, terraform_data.docker-build]
  provisioner "local-exec" {
    command = <<EOT
    docker image tag ${local.ecr_url} ${local.ecr_url}:${var.image_version}
    docker image tag ${local.ecr_url} ${local.ecr_url}:latest
    docker image push ${local.ecr_url}:${var.image_version}
    docker image push ${local.ecr_url}:latest
    EOT
  }
}

resource "aws_ecs_task_definition" "ecs-task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${local.ecr_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.app_name}-service"
  task_definition = aws_ecs_task_definition.ecs-task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  cluster         = var.ecs_cluster_arn

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.app_security_group_id]
    assign_public_ip = var.is_public
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tr.arn
    container_name   = var.app_name
    container_port   = var.port
  }
}

resource "aws_lb_target_group" "lb_tr" {
  name        = "tf-ecs-mtc-lb"
  port        = var.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener_rule" "http_rule" {
  listener_arn = var.alb_listener_arn
  condition {
    path_pattern {
      values = [var.path_pattern]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tr.arn
  }

}
