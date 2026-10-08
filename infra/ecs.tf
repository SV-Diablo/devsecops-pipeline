locals {
  container_name = "api"
}

resource "aws_ecs_cluster" "main" {
  name = var.project

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.main.arn
}

# Execution role: what ECS itself needs to start the task (pull the image, write logs).
resource "aws_iam_role" "execution" {
  name = "${var.project}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: what the application code may call in AWS. Nothing, on purpose.
resource "aws_iam_role" "task" {
  name = "${var.project}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_ecs_task_definition" "api" {
  family                   = var.project
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  # The only writable path inside the container.
  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([{
    name                   = local.container_name
    image                  = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
    essential              = true
    user                   = "10001"
    readonlyRootFilesystem = true
    privileged             = false

    linuxParameters = {
      initProcessEnabled = true
      capabilities       = { drop = ["ALL"] }
    }

    portMappings = [{ containerPort = 8000, protocol = "tcp" }]
    mountPoints  = [{ sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }]

    healthCheck = {
      command     = ["CMD", "python", "-c", "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.region
        awslogs-stream-prefix = local.container_name
      }
    }
  }])
}

resource "aws_ecs_service" "api" {
  #checkov:skip=CKV_AWS_333:Public IP instead of a NAT gateway or load balancer to keep the demo under ~USD 15/month. Ingress is limited to allowed_ingress_cidrs.
  name             = var.project
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.api.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  enable_execute_command = false

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.api.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # CI registers a new task definition revision on every deploy; Terraform must not
  # roll it back to the bootstrap one.
  lifecycle {
    ignore_changes = [task_definition]
  }
}
