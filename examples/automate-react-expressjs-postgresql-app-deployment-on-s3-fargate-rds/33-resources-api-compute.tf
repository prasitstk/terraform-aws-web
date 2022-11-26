########################
# CloudWatch Resources #
########################

resource "aws_cloudwatch_log_group" "api_task_loggrp" {
  name = "/ecs/${var.sys_name}-api-task"
}

#################
# ECS Resources #
#################

resource "aws_ecs_cluster" "api_ctr_cluster" {
  name = "${var.sys_name}-api-ctr-cluster" # Naming the cluster
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

resource "aws_iam_role" "api_ecsTaskExecutionRole" {
  name               = "${var.sys_name}-api-ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "api_ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.api_ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_ecr_image" "api_image" {
  depends_on      = [null_resource.docker_build_push_to_ecr_repo]
  repository_name = "${aws_ecr_repository.api_ctr_img_repo.name}"
  image_tag       = "${var.api_ctr_img_tag}"
}

resource "aws_ecs_task_definition" "api_taskdef" {
  depends_on = [null_resource.docker_build_push_to_ecr_repo]

  family                   = "${var.sys_name}-api-taskdef" # Naming our task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.sys_name}-api-task",
      "image": "${aws_ecr_repository.api_ctr_img_repo.repository_url}@${data.aws_ecr_image.api_image.image_digest}",
      "environment": [
        {"name": "PORT", "value": "${var.api_cfg_port}"},
        {"name": "CORS_ORIGIN", "value": "https://${aws_route53_record.app_dns_record.fqdn}"},
        {"name": "DB_HOST", "value": "${aws_db_instance.data_dbi.address}"},
        {"name": "DB_USER", "value": "${aws_db_instance.data_dbi.username}"},
        {"name": "DB_USER_PASSWORD", "value": "${var.data_master_db_password}"},
        {"name": "DB_NAME", "value": "${aws_db_instance.data_dbi.db_name}"}
      ],
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${var.api_cfg_port},
          "hostPort": ${var.api_cfg_port}
        }
      ],
      "memory": 512,
      "cpu": 256,
      "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.api_task_loggrp.name}",
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
  execution_role_arn       = "${aws_iam_role.api_ecsTaskExecutionRole.arn}"
}

resource "aws_ecs_service" "api_service" {
  name            = "${var.sys_name}-api-service"                  # Naming our first service
  cluster         = "${aws_ecs_cluster.api_ctr_cluster.id}"        # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.api_taskdef.arn}"   # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = var.api_svc_fixed_task_count                   # Setting the number of containers we want deployed to 3
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api_tgtgrp.arn
    container_name   = "${var.sys_name}-api-task"
    container_port   = var.api_cfg_port
  }

  network_configuration {
    subnets          = [for s in aws_subnet.sys_private_subnets: "${s.id}"]
    security_groups  = ["${aws_security_group.api_svc_sg.id}"]
    assign_public_ip = false
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
