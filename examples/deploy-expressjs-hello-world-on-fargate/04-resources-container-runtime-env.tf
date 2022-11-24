########################
# CloudWatch Resources #
########################

resource "aws_cloudwatch_log_group" "app_task_loggrp" {
  name = "/ecs/app-task"
}

#################
# ECS Resources #
#################

resource "aws_ecs_cluster" "app_ctr_cluster" {
  name = "app-ctr-cluster" # Naming the cluster
}

data "aws_ecr_image" "app_image" {
  depends_on      = [null_resource.docker_build_push_to_ecr_repo]
  repository_name = "${aws_ecr_repository.app_ctr_img_repo.name}"
  image_tag       = "${var.app_ctr_img_tag}"
}

resource "aws_ecs_task_definition" "app_taskdef" {
  depends_on = [null_resource.docker_build_push_to_ecr_repo]

  family                   = "app-taskdef" # Naming our task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-task",
      "image": "${aws_ecr_repository.app_ctr_img_repo.repository_url}@${data.aws_ecr_image.app_image.image_digest}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256,
      "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.app_task_loggrp.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.app_ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "app_ecsTaskExecutionRole" {
  name               = "app-ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_assume_role_policy.json}"
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "app_ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.app_ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "app_service" {
  name            = "app-service"                                  # Naming our first service
  cluster         = "${aws_ecs_cluster.app_ctr_cluster.id}"        # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.app_taskdef.arn}"   # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = var.app_svc_fixed_task_count                   # Setting the number of containers we want deployed to 3
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tgtgrp.arn
    container_name   = "app-task"
    container_port   = 3000
  }

  network_configuration {
    subnets          = [for s in aws_subnet.app_public_subnets: "${s.id}"]
    security_groups  = ["${aws_security_group.app_svc_sg.id}"]
    assign_public_ip = true # Providing our containers with public IPs
  }
  
  # Redeploy Service On Every Apply
  force_new_deployment = true
  
  # triggers = {
  #   redeployment = timestamp()
  # }
  
  # # Optional: Allow external changes without Terraform plan difference
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }
  
}
