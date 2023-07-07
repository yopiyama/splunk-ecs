resource "aws_ecs_cluster" "splunk-cluster" {
  name = "splunk-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-capacity" {
  capacity_providers = ["FARGATE"]
  cluster_name       = aws_ecs_cluster.splunk-cluster.name
}

resource "aws_ecs_task_definition" "splunk-service-def" {
  container_definitions = jsonencode(
    [
      {
        cpu         = 0
        image       = "splunk/splunk:latest"
        essential = true
        environment = [
          {
            name  = "SPLUNK_START_ARGS",
            value = "--accept-license"
          },
          {
            name  = "SPLUNK_PASSWORD",
            value = "changem3N0w!"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/splunk-cluster/splunk-service"
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "ecs"
          }
        }
        name = "splunk-service"
        portMappings = [
          {
            containerPort = 8000
            hostPort      = 8000
            protocol      = "tcp"
          },
          {
            containerPort = 9997
            hostPort      = 9997
            protocol      = "tcp"
          },
          {
            containerPort = 2049
            hostPort      = 2049
            protocol      = "tcp"
          }
        ]
        volumesFrom = []
        mountPoints = [
          {
            sourceVolume  = "splunk-var"
            containerPath = "/opt/splunk/var"
            readOnly      = false
          },
          {
            sourceVolume  = "splunk-etc"
            containerPath = "/opt/splunk/etc"
            readOnly      = false
          }
        ]
      }
    ]
  )
  family                   = "splunk-service"
  execution_role_arn       = aws_iam_role.task-execution-role.arn
  task_role_arn            = aws_iam_role.ecs-service-role.arn
  cpu                      = "2048"
  memory                   = "4096"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  tags_all = {}
  volume {
    name = "splunk-var"
    efs_volume_configuration {
        file_system_id = aws_efs_file_system.splunk-var.id
        root_directory = "/"
      }
  }
  volume {
    name = "splunk-etc"
    efs_volume_configuration {
        file_system_id = aws_efs_file_system.splunk-etc.id
        root_directory = "/"
      }
  }
}

resource "aws_ecs_service" "splunk-service" {
  name            = "splunk-service"
  cluster         = aws_ecs_cluster.splunk-cluster.name
  task_definition = aws_ecs_task_definition.splunk-service-def.arn

  launch_type         = "FARGATE"
  platform_version    = "LATEST"
  propagate_tags      = "NONE"
  scheduling_strategy = "REPLICA"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 0

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  network_configuration {
    assign_public_ip = true
    security_groups = [
      aws_security_group.splunk-sg.id
    ]
    subnets = [
      aws_subnet.subnet-public-1a.id,
      aws_subnet.subnet-public-1c.id
    ]
  }
}

